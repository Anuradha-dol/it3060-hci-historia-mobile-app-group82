# HISTORIA

IT3060 HCI Group Project.

HISTORIA is an application for exploring historical places, finding local guides, and connecting with travel buddies.

## Backend Setup

Open the `backend` folder in IntelliJ IDEA, or import:

`backend/pom.xml`

as a Maven project.

### Local Configuration

For local credentials, create the following file on your machine:

```text
backend/src/main/resources/application-local.yml
```

Add your own local configuration values for:

- PostgreSQL database
- Email / SMTP
- Google OAuth 2.0
- JWT

The `application-local.yml` file is ignored by Git, so sensitive credentials will not be pushed to the repository.

### Run Tests

Open a terminal from the project root and run:

```bash
cd backend
.\mvnw.cmd clean test
```

### Run the Backend

```bash
.\mvnw.cmd spring-boot:run
```
