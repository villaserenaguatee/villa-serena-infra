# PostgreSQL 17 bootstrap

PostgreSQL is provisioned once with Ansible, independent of later application CI/CD.

- Image: `postgres:17`
- Volume: `villa-serena-db_pgdata` (persistent across container restarts/upgrades).
- No host port publication. Only containers on `villa-serena-backend` can connect
  using host `postgres`? **Note:** the database service container has Compose DNS
  name `postgres` on that shared network.
- Authentication: root-only password file fetched from AWS SSM Parameter Store.
- Password is never placed in Terraform state, GitHub, or playbook output.
- Credentials are only applied on first initialization of the Docker volume;
  changing the SSM parameter later does **not** rotate the existing DB user's password.
- `docker compose up -d` is rerunnable without deleting the named volume.
- Backups are still required; a Docker volume alone is not a backup.

## Before running the manual GitHub Actions workflow

1. Apply the new IAM policy in `aws/identity`:
   `terraform plan -var='aws_region=us-east-1'`, inspect, then apply.
2. Create one SecureString parameter called
   `/villa-serena/prod/postgres/password` in us-east-1, using AWS CLI,
   AWS console, or an approved secrets workflow. Use a strong random password
   of at least 16 characters. **Do not type the secret as a literal shell command
   or commit it to Git.** Example secure terminal input:

   ```bash
   read -rsp 'Database password: ' PG_PASSWORD; echo
   aws ssm put-parameter --name /villa-serena/prod/postgres/password \
     --type SecureString --value "$PG_PASSWORD" --region us-east-1
   unset PG_PASSWORD
   ```

   Use `--overwrite` only if the parameter exists and rotation is intended.
   EC2's IAM role uses `ssm:GetParameter` and the default `aws/ssm` key.

3. Merge this PR and manually dispatch `Ansible PostgreSQL 17` from main.
4. Verify on EC2 through Session Manager:

   ```bash
   docker compose -p villa-serena-db -f /opt/villa-serena/postgres/compose.yml ps
   docker volume ls
   docker inspect villa-serena-db-postgres-1 --format '{{"{{"}}.State.Health.Status{{"}}"}}'
   ```

The playbook never executes `docker compose down -v` and does not touch the
application Compose project. Do not expose PostgreSQL 5432 in Security Groups.
