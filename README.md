# Historia Mobile App

HISTORIA - A mobile application for exploring historical places, finding local guides, and connecting with travel buddies. Developed for IT3060 HCI.

## Backend

Create `backend/src/main/resources/application-local.yml` from `application-local.example.yml` and add your own database and mail credentials there. The local file is ignored by Git.

In IntelliJ IDEA, open the `backend` folder or import `backend/pom.xml` as the Maven project.

```powershell
cd backend
.\mvnw.cmd clean test
```
