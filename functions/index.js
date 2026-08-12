const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getMessaging} = require("firebase-admin/messaging");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {defineString} = require("firebase-functions/params");
const {GoogleAuth} = require("google-auth-library");

initializeApp();

const db = getFirestore();
const auth = getAuth();
const bootstrapAdminEmail = defineString("BOOTSTRAP_ADMIN_EMAIL");
const aiTranslationModel = defineString("AI_TRANSLATION_MODEL", {
  default: "gemini-2.5-flash",
});

exports.notifyInternalChatMessage = onDocumentCreated(
    "chat_messages/{messageId}",
    async (event) => {
      const message = event.data?.data();
      if (!message || message.isDeleted === true) return;
      const threadId = clean(message.threadId);
      const senderId = clean(message.senderId);
      if (!threadId || !senderId) return;

      const thread = await db.collection("communication_threads")
          .doc(threadId).get();
      if (!thread.exists) return;
      const recipients = (thread.data().participantIds || [])
          .map(clean)
          .filter((uid) => uid && uid !== senderId);
      if (recipients.length === 0) return;

      const tokenSnapshots = await Promise.all(recipients.map((uid) =>
        db.collection("push_device_tokens")
            .where("userId", "==", uid)
            .where("isActive", "==", true)
            .get(),
      ));
      const tokens = [...new Set(tokenSnapshots.flatMap((snapshot) =>
        snapshot.docs.map((doc) => clean(doc.data().token)),
      ).filter(Boolean))];
      if (tokens.length === 0) return;

      const senderName = clean(message.senderName) || "School user";
      const text = clean(message.text) || clean(message.attachmentName) ||
        "Sent an attachment";
      await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "New internal chat message",
          body: `${senderName}: ${text}`,
        },
        data: {type: "chat", threadId, referenceId: threadId},
        android: {
          priority: "high",
          notification: {
            sound: "default",
          },
        },
        apns: {payload: {aps: {sound: "default", badge: 1}}},
      });
    },
);

async function requireQuestionPaperTranslator(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }
  const callerEmail = clean(request.auth.token.email).toLowerCase();
  const configuredBootstrapEmail = clean(bootstrapAdminEmail.value())
      .toLowerCase();
  if (configuredBootstrapEmail && callerEmail === configuredBootstrapEmail) {
    return;
  }
  const snapshot = await db.collection("user_roles").doc(request.auth.uid).get();
  if (!snapshot.exists || snapshot.data().isActive !== true) {
    throw new HttpsError("permission-denied", "Your account is not active.");
  }
  const assignment = snapshot.data();
  const normaliseRole = (value) => clean(value).toLowerCase()
      .replace(/[^a-z0-9]/g, "");
  const roleId = clean(assignment.roleId);
  const roleTokens = [
    normaliseRole(roleId),
    normaliseRole(assignment.roleName),
  ];
  let allowed = roleTokens.some((role) =>
    ["teacher", "admin", "schooladmin", "superadmin"].includes(role),
  );
  if (!allowed && roleId) {
    const roleSnapshot = await db.collection("app_roles").doc(roleId).get();
    const role = roleSnapshot.data() || {};
    const permissions = Array.isArray(role.permissions) ? role.permissions : [];
    allowed = role.isActive !== false && (
      normaliseRole(role.name).includes("admin") ||
      permissions.includes("questionPapersManage") ||
      permissions.includes("examsManage") ||
      permissions.includes("rolesManage")
    );
  }
  if (!allowed) {
    throw new HttpsError(
        "permission-denied",
        "Only teachers and administrators can translate question papers.",
    );
  }
}

exports.translateQuestionPaperText = onCall({timeoutSeconds: 60}, async (request) => {
  await requireQuestionPaperTranslator(request);
  const targetLanguage = clean(request.data && request.data.targetLanguage);
  const subject = clean(request.data && request.data.subject);
  const texts = Array.isArray(request.data && request.data.texts) ?
    request.data.texts.map(clean) : [];
  if (!["urdu", "english"].includes(targetLanguage)) {
    throw new HttpsError("invalid-argument", "Select Urdu or English.");
  }
  if (!texts.length || texts.length > 100 || texts.some((text) => !text)) {
    throw new HttpsError(
        "invalid-argument",
        "Provide between 1 and 100 non-empty question-paper texts.",
    );
  }

  const targetName = targetLanguage === "urdu" ? "Urdu" : "English";
  const prompt = [
    `Translate every JSON array item into ${targetName}.`,
    "The input may be Roman Urdu, Urdu, or English.",
    `These are ${subject || "school"} question-paper prompts and options.`,
    "Preserve numbering, blanks, symbols, formulas, names, and meaning.",
    "Use natural, age-appropriate academic language.",
    "Return only one valid JSON array of strings in the same order.",
    JSON.stringify(texts),
  ].join("\n");

  try {
    const googleAuth = new GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/cloud-platform"],
    });
    const projectId = await googleAuth.getProjectId();
    const client = await googleAuth.getClient();
    const token = await client.getAccessToken();
    const model = aiTranslationModel.value();
    const requestBody = JSON.stringify({
      contents: [{role: "user", parts: [{text: prompt}]}],
      generationConfig: {
        temperature: 0.1,
        responseMimeType: "application/json",
      },
    });
    let payload;
    let lastFailure = "";
    for (const location of ["global", "us-central1"]) {
      const host = location === "global" ?
        "aiplatform.googleapis.com" :
        `${location}-aiplatform.googleapis.com`;
      const endpoint = `https://${host}/v1/projects/${projectId}/locations/` +
        `${location}/publishers/google/models/${model}:generateContent`;
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token.token || token}`,
          "Content-Type": "application/json",
        },
        body: requestBody,
      });
      if (response.ok) {
        payload = await response.json();
        break;
      }
      lastFailure = `${response.status}: ${await response.text()}`;
      console.error(
          `Vertex translation failed in ${location}`,
          lastFailure,
      );
    }
    if (!payload) throw new Error(`Vertex AI unavailable (${lastFailure})`);
    const output = payload.candidates && payload.candidates[0] &&
      payload.candidates[0].content && payload.candidates[0].content.parts &&
      payload.candidates[0].content.parts[0].text;
    const jsonText = clean(output).replace(/^```(?:json)?\s*/i, "")
        .replace(/\s*```$/, "");
    const translations = JSON.parse(jsonText || "[]");
    if (!Array.isArray(translations) || translations.length !== texts.length) {
      throw new Error("AI returned an invalid translation array.");
    }
    return {translations: translations.map(clean)};
  } catch (error) {
    console.error("Question paper translation failed", error);
    throw new HttpsError(
        "unavailable",
        "AI translation service is not ready. Enable Vertex AI for this " +
          "Firebase project and deploy the latest Functions build.",
    );
  }
});

function clean(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normaliseLogin(value) {
  const login = clean(value).toLowerCase();
  if (!login) {
    throw new HttpsError(
        "invalid-argument",
        "Email, username or mobile number is required.",
    );
  }

  if (login.includes("@")) return login;

  const safeUsername = login.replace(/[^a-z0-9._-]/g, "");
  if (!safeUsername) {
    throw new HttpsError(
        "invalid-argument",
        "Enter a valid username or mobile number.",
    );
  }

  return `${safeUsername}@almustafa.school`;
}

async function requireUserManagementPermission(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }

  const assignmentSnapshot = await db
      .collection("user_roles")
      .doc(request.auth.uid)
      .get();

  if (!assignmentSnapshot.exists) {
    throw new HttpsError(
        "permission-denied",
        "Your user account has no active role assignment.",
    );
  }

  const assignment = assignmentSnapshot.data();

  if (assignment.isActive !== true) {
    throw new HttpsError("permission-denied", "Your account is inactive.");
  }

  const roleId = clean(assignment.roleId);
  const roleSnapshot = await db.collection("app_roles").doc(roleId).get();

  if (!roleSnapshot.exists || roleSnapshot.data().isActive !== true) {
    throw new HttpsError("permission-denied", "Your assigned role is inactive.");
  }

  const permissions = Array.isArray(roleSnapshot.data().permissions) ?
    roleSnapshot.data().permissions :
    [];

  const allowed = roleId === "super_admin" ||
    permissions.includes("usersManage") ||
    permissions.includes("rolesManage");

  if (!allowed) {
    throw new HttpsError(
        "permission-denied",
        "You do not have permission to manage user accounts.",
    );
  }

  return {
    callerUid: request.auth.uid,
    callerEmail: request.auth.token.email || "",
  };
}

exports.bootstrapUserAccountAdministration = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }

  const callerEmail = clean(request.auth.token.email).toLowerCase();
  const allowedEmail = clean(bootstrapAdminEmail.value()).toLowerCase();
  if (!allowedEmail || callerEmail !== allowedEmail) {
    throw new HttpsError(
        "permission-denied",
        "This account is not authorised for Super Admin bootstrap.",
    );
  }

  const existingSuperAdmins = await db
      .collection("user_roles")
      .where("roleId", "==", "super_admin")
      .get();
  const hasActiveSuperAdmin = existingSuperAdmins.docs.some(
      (doc) => doc.data().isActive === true,
  );

  if (hasActiveSuperAdmin) {
    throw new HttpsError(
        "permission-denied",
        "A Super Admin already exists. Ask that administrator to grant access.",
    );
  }

  const caller = await auth.getUser(request.auth.uid);
  const now = FieldValue.serverTimestamp();
  const permissions = [
    "studentsView", "studentsCreate", "studentsEdit", "studentsDelete",
    "teachersView", "teachersCreate", "teachersEdit", "teachersDelete",
    "staffView", "staffCreate", "staffEdit", "staffDelete",
    "classesView", "classesManage", "attendanceView", "attendanceMark",
    "attendanceEdit", "feesView", "feesCollect", "feesManage",
    "feesReports", "examsView", "examsManage", "dateSheetsView",
    "dateSheetsManage", "resultsView", "resultsEnter", "resultsPublish",
    "timetableView", "timetableManage", "homeworkView", "homeworkCreate",
    "homeworkReview", "noticesView", "noticesManage", "calendarView",
    "calendarManage", "parentsView", "parentsManage", "reportsView",
    "reportsExport", "settingsView", "settingsManage", "usersManage",
    "rolesManage", "auditLogsView",
  ];

  const batch = db.batch();
  batch.set(db.collection("app_roles").doc("super_admin"), {
    name: "Super Admin",
    description: "Complete access to all ERP modules and actions.",
    permissions,
    isSystemRole: true,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  }, {merge: true});
  batch.set(db.collection("user_roles").doc(request.auth.uid), {
    userId: request.auth.uid,
    userName: caller.displayName || caller.email || "Super Admin",
    email: caller.email || "",
    username: caller.email ? caller.email.split("@")[0] : "",
    roleId: "super_admin",
    roleName: "Super Admin",
    branchId: "main",
    linkedEntityType: "",
    linkedEntityId: "",
    isActive: true,
    mustChangePassword: false,
    assignedBy: "secure-bootstrap",
    assignedAt: now,
    createdAt: now,
    updatedAt: now,
  }, {merge: true});
  await batch.commit();

  return {bootstrapped: true, uid: request.auth.uid};
});

exports.createUserAccount = onCall(async (request) => {
  const caller = await requireUserManagementPermission(request);
  const data = request.data || {};

  const displayName = clean(data.displayName);
  const loginEmail = normaliseLogin(data.login);
  const username = loginEmail.endsWith("@almustafa.school") ?
    loginEmail.split("@")[0] :
    clean(data.username).toLowerCase();
  const password = clean(data.password);
  const roleId = clean(data.roleId);
  const branchId = clean(data.branchId) || "main";
  const linkedEntityType = clean(data.linkedEntityType);
  const linkedEntityId = clean(data.linkedEntityId);

  if (!displayName) {
    throw new HttpsError("invalid-argument", "Display name is required.");
  }
  if (password.length < 6) {
    throw new HttpsError(
        "invalid-argument",
        "Password must contain at least 6 characters.",
    );
  }
  if (!roleId) {
    throw new HttpsError("invalid-argument", "Select a role.");
  }

  const roleSnapshot = await db.collection("app_roles").doc(roleId).get();
  if (!roleSnapshot.exists || roleSnapshot.data().isActive !== true) {
    throw new HttpsError("failed-precondition", "Selected role is not active.");
  }

  let userRecord;

  try {
    userRecord = await auth.createUser({
      email: loginEmail,
      password,
      displayName,
      disabled: false,
      emailVerified: false,
    });
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
          "already-exists",
          "A user with this email or username already exists.",
      );
    }
    if (error.code === "auth/invalid-password") {
      throw new HttpsError("invalid-argument", "Password is not valid.");
    }
    if (error.code === "auth/invalid-email") {
      throw new HttpsError("invalid-argument", "Email or username is not valid.");
    }
    throw error;
  }

  const now = FieldValue.serverTimestamp();

  try {
    await db.collection("user_roles").doc(userRecord.uid).set({
      userId: userRecord.uid,
      userName: displayName,
      email: loginEmail,
      username,
      roleId,
      roleName: roleSnapshot.data().name || roleId,
      branchId,
      linkedEntityType,
      linkedEntityId,
      isActive: true,
      mustChangePassword: true,
      assignedBy: caller.callerEmail || caller.callerUid,
      assignedAt: now,
      createdAt: now,
      updatedAt: now,
    });
  } catch (error) {
    await auth.deleteUser(userRecord.uid);
    throw new HttpsError(
        "internal",
        `Authentication user was rolled back because role assignment failed: ${error.message}`,
    );
  }

  return {
    uid: userRecord.uid,
    email: loginEmail,
    username,
    displayName,
    roleId,
    roleName: roleSnapshot.data().name || roleId,
    disabled: false,
  };
});

exports.listUserAccounts = onCall(async (request) => {
  await requireUserManagementPermission(request);

  const requestedPageSize = Number(request.data?.pageSize || 100);
  const pageSize = Math.max(1, Math.min(requestedPageSize, 1000));
  const pageToken = clean(request.data?.pageToken) || undefined;

  const result = await auth.listUsers(pageSize, pageToken);
  const roleSnapshots = await Promise.all(
      result.users.map((user) =>
        db.collection("user_roles").doc(user.uid).get()),
  );

  const users = result.users.map((user, index) => {
    const roleData = roleSnapshots[index].exists ?
      roleSnapshots[index].data() :
      {};

    return {
      uid: user.uid,
      email: user.email || "",
      username: roleData.username || "",
      displayName: user.displayName || roleData.userName || "",
      disabled: user.disabled,
      emailVerified: user.emailVerified,
      roleId: roleData.roleId || "",
      roleName: roleData.roleName || "Not Assigned",
      branchId: roleData.branchId || "main",
      linkedEntityType: roleData.linkedEntityType || "",
      linkedEntityId: roleData.linkedEntityId || "",
      isActive: roleData.isActive !== false,
      createdAt: user.metadata.creationTime || "",
      lastSignInAt: user.metadata.lastSignInTime || "",
    };
  });

  return {
    users,
    nextPageToken: result.pageToken || "",
  };
});

exports.listChatParticipants = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }

  const callerRole = await db
      .collection("user_roles")
      .doc(request.auth.uid)
      .get();
  if (!callerRole.exists || callerRole.data().isActive !== true) {
    throw new HttpsError(
        "permission-denied",
        "Your user account has no active role assignment.",
    );
  }

  // Load role assignments in one query. Issuing up to 1,000 Firestore reads in
  // parallel can make this callable fail with a generic `internal` error.
  const [result, roleQuery] = await Promise.all([
    auth.listUsers(1000),
    db.collection("user_roles").get(),
  ]);
  const rolesByUserId = new Map(
      roleQuery.docs.map((document) => [document.id, document.data()]),
  );

  const users = result.users
      .map((user) => {
        const roleData = rolesByUserId.get(user.uid) || {};
        return {
          uid: user.uid,
          email: user.email || "",
          displayName: user.displayName || roleData.userName || "",
          username: roleData.username || "",
          roleId: roleData.roleId || "",
          roleName: roleData.roleName || "Not Assigned",
          linkedEntityType: roleData.linkedEntityType || "",
          linkedEntityId: roleData.linkedEntityId || "",
          disabled: user.disabled,
          emailVerified: user.emailVerified,
          isActive: roleData.isActive === true,
          branchId: roleData.branchId || "main",
          createdAt: user.metadata.creationTime || "",
          lastSignInAt: user.metadata.lastSignInTime || "",
        };
      })
      .filter((user) =>
        user.uid !== request.auth.uid &&
        !user.disabled &&
        user.isActive &&
        user.roleId,
      );

  return {users};
});

exports.setUserAccountDisabled = onCall(async (request) => {
  const caller = await requireUserManagementPermission(request);
  const uid = clean(request.data?.uid);
  const disabled = request.data?.disabled === true;

  if (!uid) {
    throw new HttpsError("invalid-argument", "User UID is required.");
  }
  if (uid === caller.callerUid && disabled) {
    throw new HttpsError(
        "failed-precondition",
        "You cannot disable your own logged-in account.",
    );
  }

  const user = await auth.updateUser(uid, {disabled});

  await db.collection("user_roles").doc(uid).set({
    userId: uid,
    email: user.email || "",
    userName: user.displayName || "",
    isActive: !disabled,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  return {
    uid,
    disabled: user.disabled,
  };
});

exports.updateUserAccount = onCall(async (request) => {
  await requireUserManagementPermission(request);

  const data = request.data || {};
  const uid = clean(data.uid);
  const displayName = clean(data.displayName);
  const loginEmail = normaliseLogin(data.login);
  const username = loginEmail.endsWith("@almustafa.school") ?
    loginEmail.split("@")[0] :
    "";
  const branchId = clean(data.branchId) || "main";
  const linkedEntityType = clean(data.linkedEntityType);
  const linkedEntityId = clean(data.linkedEntityId);

  if (!uid || !displayName) {
    throw new HttpsError(
        "invalid-argument",
        "User UID and display name are required.",
    );
  }

  let user;
  try {
    user = await auth.updateUser(uid, {
      displayName,
      email: loginEmail,
    });
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
          "already-exists",
          "This username, mobile number or email is already in use.",
      );
    }
    if (error.code === "auth/user-not-found") {
      throw new HttpsError("not-found", "Firebase user was not found.");
    }
    if (error.code === "auth/invalid-email") {
      throw new HttpsError(
          "invalid-argument",
          "Enter a valid username, mobile number or email.",
      );
    }
    throw error;
  }

  await db.collection("user_roles").doc(uid).set({
    userId: uid,
    userName: displayName,
    email: user.email || loginEmail,
    username,
    branchId,
    linkedEntityType,
    linkedEntityId,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  return {
    uid,
    displayName,
    email: user.email || loginEmail,
    username,
  };
});

exports.updateUserAccountRole = onCall(async (request) => {
  await requireUserManagementPermission(request);

  const uid = clean(request.data?.uid);
  const roleId = clean(request.data?.roleId);
  const branchId = clean(request.data?.branchId) || "main";

  if (!uid || !roleId) {
    throw new HttpsError(
        "invalid-argument",
        "User UID and role are required.",
    );
  }

  const roleSnapshot = await db.collection("app_roles").doc(roleId).get();
  if (!roleSnapshot.exists || roleSnapshot.data().isActive !== true) {
    throw new HttpsError("failed-precondition", "Selected role is not active.");
  }

  const user = await auth.getUser(uid);

  await db.collection("user_roles").doc(uid).set({
    userId: uid,
    userName: user.displayName || "",
    email: user.email || "",
    roleId,
    roleName: roleSnapshot.data().name || roleId,
    branchId,
    isActive: !user.disabled,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  return {
    uid,
    roleId,
    roleName: roleSnapshot.data().name || roleId,
  };
});

exports.generateUserPasswordResetLink = onCall(async (request) => {
  await requireUserManagementPermission(request);

  const email = clean(request.data?.email).toLowerCase();
  if (!email) {
    throw new HttpsError("invalid-argument", "User email is required.");
  }

  try {
    const link = await auth.generatePasswordResetLink(email);
    return {link};
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      throw new HttpsError("not-found", "Firebase user was not found.");
    }
    throw error;
  }
});
