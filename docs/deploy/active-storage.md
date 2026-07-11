# ActiveStorage

upopoy uses Rails ActiveStorage for drive file uploads and file version history. The `DriveItem` and `DriveItemVersion` models attach files through ActiveStorage, so storage durability matters for user documents and markdown content.

## Current Defaults

The current production configuration uses the local disk service:

```ruby
config.active_storage.service = :local
```

The `:local` service is defined in `backend/config/storage.yml`:

```yaml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>
```

In the Kamal deployment config, `/rails/storage` is mounted as a persistent Docker volume:

```yaml
volumes:
  - "backend_storage:/rails/storage"
```

This is enough for a single-server deployment when the volume is backed up and kept on the same host as the Rails container.

## Local Disk Storage

Use local disk storage when:

- The deployment has a single Rails web host.
- Upload volume is small or moderate.
- You have reliable host-level backups for the mounted storage volume.

Keep these requirements in place:

- Mount a persistent volume at `/rails/storage`.
- Include that volume in backup and restore procedures.
- Do not run multiple app servers unless they all share the same storage path.
- Do not delete `backend_storage` during deploys, rebuilds, or rollbacks.

## S3-Compatible Storage

Use S3 or an S3-compatible object store when:

- The app runs on multiple web hosts.
- Uploaded files must survive host replacement.
- Backups, replication, lifecycle policies, or CDN integration should be managed outside the Rails host.

Add the S3 service in `backend/config/storage.yml`:

```yaml
amazon:
  service: S3
  access_key_id: <%= ENV.fetch("AWS_ACCESS_KEY_ID") %>
  secret_access_key: <%= ENV.fetch("AWS_SECRET_ACCESS_KEY") %>
  region: <%= ENV.fetch("AWS_REGION") %>
  bucket: <%= ENV.fetch("ACTIVE_STORAGE_BUCKET") %>
```

For S3-compatible providers, add endpoint options if the provider requires them:

```yaml
amazon:
  service: S3
  access_key_id: <%= ENV.fetch("AWS_ACCESS_KEY_ID") %>
  secret_access_key: <%= ENV.fetch("AWS_SECRET_ACCESS_KEY") %>
  region: <%= ENV.fetch("AWS_REGION", "auto") %>
  bucket: <%= ENV.fetch("ACTIVE_STORAGE_BUCKET") %>
  endpoint: <%= ENV.fetch("AWS_ENDPOINT_URL") %>
  force_path_style: true
```

Then switch production to the S3 service in `backend/config/environments/production.rb`:

```ruby
config.active_storage.service = :amazon
```

If you want to choose the service per deployment environment, use an environment variable:

```ruby
config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "local").to_sym
```

## Required Gems

The app already includes ActiveStorage. S3 storage also requires the AWS S3 SDK gem in `backend/Gemfile`:

```ruby
gem "aws-sdk-s3", require: false
```

After adding it, install dependencies and rebuild the backend image:

```sh
mise exec -- bundle install --gemfile backend/Gemfile
```

## Deployment Secrets

For S3 storage, set these Rails environment variables:

```sh
ACTIVE_STORAGE_SERVICE=amazon
ACTIVE_STORAGE_BUCKET=upopoy-production-files
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1
```

For S3-compatible storage, also set:

```sh
AWS_ENDPOINT_URL=https://...
```

Store secrets in the deployment secret manager, not in `storage.yml` or committed files.

## Public Access

Keep the bucket private. ActiveStorage should control file access through Rails-generated URLs instead of exposing the bucket directly.

If a CDN is introduced later, keep the origin private and document the URL signing or proxying behavior before enabling public file delivery.

## Migration From Local To S3

Changing the service for new uploads does not automatically move existing blobs. Existing `active_storage_blobs.service_name` values continue to point to the service used when each blob was created.

For a migration:

1. Stop writes or put the app in maintenance mode.
2. Copy existing files from `/rails/storage` to the target object store.
3. Verify object keys and checksums.
4. Update `active_storage_blobs.service_name` only after the objects are present in the new service.
5. Deploy the new ActiveStorage service configuration.
6. Test downloads, uploads, markdown reads, and version restore.

For small deployments, a simpler and safer option is to keep existing local blobs on the local service and use S3 only for new uploads after the switch.

## Backup Checklist

For local disk storage:

- Back up the `backend_storage` Docker volume.
- Back up the database at the same point in time as file storage.
- Test restoring both database rows and files together.

For S3 storage:

- Enable bucket versioning or object-lock policies if required.
- Configure lifecycle rules intentionally.
- Back up credentials and bucket policy configuration.
- Monitor failed uploads and download errors.

## Verification

After changing storage configuration:

1. Upload a file in the drive UI.
2. Open or download that file.
3. Edit a markdown file and confirm a new version is created.
4. Restore an older version.
5. Restart or redeploy the backend container.
6. Confirm the same file still opens after restart.

For S3 deployments, also confirm the object appears in the expected bucket and that the bucket remains private.
