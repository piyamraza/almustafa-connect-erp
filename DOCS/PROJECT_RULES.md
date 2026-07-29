\# Almustafa Connect ERP

\## Permanent Development Rules



Version: 1.0



\---



\# 1. Project Identity



This project is a School ERP.



It is NOT a Textile ERP.



Never mix requirements from any previous projects.



\---



\# 2. Architecture



The Master Architecture Documents are the single source of truth.



Never change:



\- Folder Structure

\- Architecture

\- BLoC Structure

\- Dependency Injection

\- Firebase Structure

\- Database Schema

\- Coding Standards



unless explicitly instructed.



\---



\# 3. Coding Style



Always provide COMPLETE files.



Never provide partial snippets unless specifically requested.



Every generated file must be production-ready.



\---



\# 4. Development Workflow



Work only one step at a time.



Wait for confirmation before moving to the next step.



Never generate multiple implementation steps together.



\---



\# 5. User Experience



Assume the developer is NOT a Flutter expert.



Never say:



"replace this line"



Instead provide the entire updated file.



\---



\# 6. Existing Code



Never redesign completed modules.



Never rewrite working code without a valid reason.



Only modify code that is directly related to the requested task.



\---



\# 7. UI Rules



Keep UI professional.



Avoid demo-style layouts.



Everything should be suitable for production.



\---



\# 8. Architecture First



Before implementing any feature:



\- verify architecture

\- verify folder placement

\- verify dependency flow



Implementation must always follow the architecture.



\---



\# 9. Naming Convention



Use meaningful names.



Avoid abbreviations.



Use consistent naming across the project.



\---



\# 10. State Management



Use BLoC only.



Do not introduce Provider, Riverpod, GetX, or any other state management solution.



\---



\# 11. Dependency Injection



Use the existing Service Locator.



Do not create objects manually when DI is already defined.



\---



\# 12. Firebase



Authentication, Firestore, Storage, and other Firebase services must use the existing architecture.



Never bypass repositories.



\---



\# 13. Navigation



Use the existing navigation structure.



Do not introduce a different routing approach without approval.



\---



\# 14. Dashboard



Dashboard is only an entry point.



Business logic belongs inside modules.



\---



\# 15. Module Development Order



Always follow the Development Roadmap.



Do not randomly jump to another module.



\---



\# 16. Code Quality



Write clean code.



Avoid duplication.



Keep files organized.



Follow SOLID principles.



\---



\# 17. Error Handling



Every feature must include proper error handling.



No silent failures.



\---



\# 18. Documentation



Whenever architecture changes:



Update:



\- CHANGELOG.md

\- PROJECT\_PROGRESS.md

\- DECISIONS\_LOG.md



if applicable.



\---



\# 19. Communication Rules



Keep explanations short.



Focus on implementation.



Avoid unnecessary theory.



\---



\# 20. Project Continuity



When starting a new chat:



Treat this file together with the Master Architecture Documents as the permanent project rules.



Continue implementation from the current project state.



Never restart project planning.



Never redesign completed architecture.



Continue exactly from the previous implementation.



