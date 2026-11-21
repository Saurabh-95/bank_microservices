# Automatic Configuration Refresh -- Setup and Troubleshooting

This document records the steps for running and troubleshooting the
GitHub → Hookdeck → Spring Cloud Config → RabbitMQ → microservices
automatic configuration refresh workflow on Windows 11.

## 1. Architecture overview

``` text
GitHub Config Repository
        |
        | Push event
        v
Hookdeck Cloud
        |
        v
Hookdeck CLI (local tunnel)
        |
        v
Config Server (localhost:8071/monitor)
        |
        v
RabbitMQ (Spring Cloud Bus)
        |
        v
Accounts / Loans / Cards
        |
        v
Updated configuration without restarting the services
```

### Component responsibilities

-   **GitHub:** Stores the external configuration files, such as
    `accounts.yml`.
-   **Hookdeck Cloud:** Receives the GitHub webhook.
-   **Hookdeck CLI:** Forwards the webhook from Hookdeck to the local
    Config Server through the tunnel.
-   **Config Server:** Receives the webhook at `/monitor` and identifies
    the changed configuration.
-   **RabbitMQ / Spring Cloud Bus:** Broadcasts the refresh event to
    connected microservices.
-   **Microservices:** Receive the event and reload their configuration.

## 2. Project details

  -------------------------------------------------------------------------------------------------------------------------------
  Item                                Value
  ----------------------------------- -------------------------------------------------------------------------------------------
  Project directory                   `S:\bank_microservices\microservicesWithConfiguration-3\microservicesWithCloundConfig-V2`

  Config Server local URL             `http://localhost:8071`

  Config Monitor endpoint             `http://localhost:8071/monitor`

  Config Server container address     `http://configserver:8071/`

  Accounts local URL                  `http://localhost:8080`

  RabbitMQ port                       `5672`

  RabbitMQ management UI port         `15672`
  -------------------------------------------------------------------------------------------------------------------------------

> Important: `localhost` is used by applications and tools running on
> the Windows host. Containers should use Docker Compose service names,
> such as `configserver` and `rabbit`, to communicate with each other.

## 3. Startup steps after restarting the laptop

### Step 1 -- Start Docker Desktop

Open Docker Desktop and wait until its engine is running.

### Step 2 -- Start the microservices

Open PowerShell and change to the project directory:

``` powershell
cd S:\bank_microservices\microservicesWithConfiguration-3\microservicesWithCloundConfig-V2
```

Start the services:

``` powershell
docker compose up -d
```

Check their status:

``` powershell
docker compose ps
```

Confirm that RabbitMQ, Config Server, Accounts, Loans and Cards are
running and healthy where health checks are configured.

### Step 3 -- Start Hookdeck CLI

Open a **separate PowerShell window**. Check that the CLI is installed:

``` powershell
hookdeck version
```

Log in if necessary (normally only required when the login session
expires or is not available):

``` powershell
hookdeck login
```

Start the listener:

``` powershell
hookdeck listen 8071 --path /monitor
```

If prompted, select the existing GitHub source and the intended
connection. Check the CLI output and confirm that the forwarding
destination points to the local Config Server monitor endpoint:

``` text
http://localhost:8071/monitor
```

Keep this PowerShell window open. Closing it stops the local tunnel. If
the CLI reports a different destination or asks for a different setup,
follow the existing connection configuration rather than creating
duplicate connections unnecessarily.

## 4. Test automatic configuration refresh

1.  Open the GitHub repository that contains the external configuration
    files.

2.  Edit a test property in `accounts.yml`, for example:

    ``` yaml
    accounts:
      message: "Welcome to SBank - Automatic Refresh Test"
    ```

3.  Commit and push the change to the branch configured in Config Server
    (for this setup, `main`).

4.  Watch the Hookdeck CLI window and confirm that it receives and
    forwards the webhook.

5.  Check the Accounts logs:

    ``` powershell
    docker compose logs --tail 50 accounts
    ```

6.  Look for messages similar to:

    ``` text
    Received remote refresh request.
    Keys refreshed [...]
    ```

7.  Call the Accounts API endpoint that exposes the configuration
    message and confirm that it returns the new value.

The exact log wording and refreshed key list can vary by Spring Cloud
version and by which properties changed.

## 5. Useful troubleshooting commands

Run these commands from the project directory unless stated otherwise.

  -----------------------------------------------------------------------------------------------
  Purpose                             Command
  ----------------------------------- -----------------------------------------------------------
  Check container status              `docker compose ps`

  View Config Server logs             `docker compose logs --tail 50 configserver`

  View Accounts logs                  `docker compose logs --tail 50 accounts`

  View all service logs               `docker compose logs --tail 50`

  Follow Config Server and Accounts   `docker compose logs -f configserver accounts`
  logs live                           

  Check Hookdeck CLI version          `hookdeck version`

  Check Config Server health          `Invoke-RestMethod http://localhost:8071/actuator/health`

  Check Accounts health               `Invoke-RestMethod http://localhost:8080/actuator/health`
  -----------------------------------------------------------------------------------------------

### Follow logs while testing a webhook

In one PowerShell window:

``` powershell
docker compose logs -f configserver accounts
```

In another window, make a GitHub push and watch for new log entries. Do
not trigger a manual `/actuator/busrefresh` during this test, because
that would make it harder to determine whether the GitHub webhook caused
the refresh.

## 6. Manual refresh tests (diagnostics only)

These endpoints are useful for isolating problems. They are not
substitutes for testing the complete GitHub-to-Hookdeck flow.

### Refresh Accounts directly

``` powershell
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8080/actuator/refresh" `
  -ContentType "application/json" `
  -Body "{}"
```

### Broadcast a Bus refresh event from Config Server

``` powershell
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8071/actuator/busrefresh" `
  -ContentType "application/json" `
  -Body "{}"
```

If the Bus test works but the GitHub push test does not, investigate the
webhook delivery, Hookdeck source/connection, CLI tunnel and `/monitor`
endpoint.

## 7. Important reminders

-   Hookdeck CLI is required while using this local tunnel approach. It
    must be running and connected for Hookdeck to forward events to the
    laptop.
-   Docker containers and Hookdeck CLI are separate processes. Starting
    the containers does not start the CLI.
-   After restarting Windows, start Docker Desktop, the Compose services
    and the Hookdeck listener again.
-   The local webhook destination is `http://localhost:8071/monitor`.
-   Containers communicate with Config Server using
    `http://configserver:8071/`, not `localhost:8071`.
-   RabbitMQ must be running and reachable by Config Server and the
    microservices.
-   A successful HTTP `200` response from `/monitor` alone does not
    prove that a refresh event reached Accounts. Confirm it in the
    microservice logs and by checking the updated API value.
-   A successful manual `/actuator/busrefresh` test proves Bus
    propagation, but does not by itself prove that GitHub webhooks are
    being forwarded correctly.
-   Keep Windows Security enabled during normal use. Do not leave
    Defender or other security protections disabled to run the CLI. If
    Windows blocks the executable again, inspect Windows Security
    **Protection history** and verify the executable before deciding
    what action to take.
-   Do not share GitHub tokens, Hookdeck secrets, or other credentials
    in screenshots or logs.

## 8. Quick diagnosis by symptom

  -----------------------------------------------------------------------
  Symptom                             What to check
  ----------------------------------- -----------------------------------
  `hookdeck` is not recognized        Confirm the CLI is installed and
                                      its location is on `PATH`; reopen
                                      PowerShell after installation if
                                      needed.

  Hookdeck CLI is offline             Start the listener again and
                                      confirm it reports that it is
                                      connected and waiting for events.

  GitHub delivery appears in Hookdeck Check the selected Hookdeck
  but is not forwarded                connection, destination URL, HTTP
                                      method and `/monitor` path.

  `/monitor` returns HTTP 200 but     Check live Config Server and
  Accounts does not refresh           Accounts logs; HTTP 200 alone is
                                      not proof of Bus publication.

  Manual `/actuator/busrefresh` works Focus on GitHub webhook delivery,
  but GitHub push does not            Hookdeck forwarding and Config
                                      Monitor.

  Accounts receives the event but     Confirm Config Server has fetched
  shows an old value                  the latest Git commit and that the
                                      changed property is part of the
                                      active configuration.

  Services cannot connect to RabbitMQ Check `docker compose ps`, RabbitMQ
                                      health and the
                                      `SPRING_RABBITMQ_HOST=rabbit`
                                      setting for containers.
  -----------------------------------------------------------------------

## 9. Official documentation

-   [Hookdeck documentation](https://hookdeck.com/docs)
-   [Hookdeck CLI documentation](https://hookdeck.com/docs/cli)
-   [Spring Cloud Config
    documentation](https://docs.spring.io/spring-cloud-config/reference/)
-   [Spring Cloud Bus
    documentation](https://docs.spring.io/spring-cloud-bus/reference/)

------------------------------------------------------------------------

**Operational checklist:** Docker Desktop running →
`docker compose up -d` → Hookdeck CLI logged in if needed →
`hookdeck listen 8071 --path /monitor` running → push a config change →
confirm refresh in Accounts logs and API.
