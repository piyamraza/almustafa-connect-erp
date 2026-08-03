const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {defineString} = require("firebase-functions/params");

initializeApp();

const db = getFirestore();
const auth = getAuth();
const bootstrapAdminEmail = defineString("BOOTSTRAP_ADMIN_EMAIL");

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
