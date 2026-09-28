# HISTORIA

IT3060 HCI group project. The app is for exploring historical places, finding local guides, and connecting with travel buddies.

## Backend

Open the `backend` folder in IntelliJ, or import `backend/pom.xml` as a Maven project.

For local credentials, create this file on your machine:

```text
backend/src/main/resources/application-local.yml
```

Then add your own database, mail, Google OAuth, and JWT values. The local file is ignored by Git.

```powershell
cd backend
.\mvnw.cmd clean test
```
