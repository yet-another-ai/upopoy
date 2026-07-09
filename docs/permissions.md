# Permission Model

This document is the source of truth for the current authorization model. Keep it in sync with backend policies, model invariants, API schemas, frontend affordances, and tests.

The model is relationship-aware RBAC with hierarchy checks. It is not pure ABAC: permissions come mainly from explicit roles (`system_admin`, group admin membership, group membership), with resource relationships such as group ancestry deciding where those roles apply.

## Principles

- Backend policies and model validations are authoritative. Frontend visibility such as `can_admin` is only a convenience for users.
- Reading and collaboration are separate from administration. Membership grants access to work inside accessible groups; admin roles grant management rights.
- Group admin rights inherit downward through descendant groups.
- System admins have global administrative rights and are treated as admins for every group.
- Every group should have at least one direct group admin.

## Roles

### System Admin

A system admin is a user with `users.system_admin = true`.

System admins can:

- Manage admin settings.
- Grant or revoke system admin rights for users.
- Administer every group, regardless of direct membership.
- Create subgroups under any group.
- Create, update, and delete project metadata in any group.

System admin is an override for authorization. It does not automatically create direct group memberships and does not satisfy the direct admin invariant stored on a group membership.

### Group Admin

A group admin is a user with a `group_memberships` row for the group where `admin = true`.

Group admin rights apply to:

- The group where the admin membership is direct.
- All descendant groups of that group.

Group admins can:

- Update or delete groups they administer.
- Configure members and admins for groups they administer.
- Create subgroups under groups they administer.
- Move a group only when they can administer both the current group and the new parent group.
- Create, update, and delete project metadata in groups they administer.

Direct group admins are always group members. When an API request includes `admin_user_ids`, the backend merges those users into `user_ids`.

### Group Member

A group member is a user with a `group_memberships` row for a group.

Group members can:

- Read groups and descendants according to the existing membership access rules.
- Read and collaborate on accessible project boards and tasks according to the existing collaboration rules.

Group members cannot:

- Create subgroups unless they are also group admins for the parent group.
- Create projects unless they are group admins for the target group.
- Manage group members or admins.
- Update or delete group metadata.
- Update or delete project metadata.

## Resource Rules

### Groups

- Any authenticated user can create a root group.
- The creator of a root group automatically becomes a direct member and direct admin of that group.
- Creating a subgroup requires admin rights on the parent group.
- Updating or deleting a group requires admin rights on the current group.
- Changing a group's parent requires admin rights on both the current group and the new parent group.
- Updating group membership or group admin assignments requires admin rights on the current group.
- A group must retain at least one direct admin after create or update.

### Projects

- Creating a project requires admin rights on the target group.
- Updating or deleting project metadata requires admin rights on the project's current or target group, depending on the operation.
- Board and task collaboration permissions are unchanged and continue to follow the existing member-based access rules.

### Admin Settings

- Reading or updating admin settings is restricted to system admins.

### Users

- User responses expose `system_admin`.
- Only system admins can grant or revoke `system_admin`.

## API Contract

Group responses include:

- `admin_user_ids`: direct group admin user IDs.
- `admins_count`: direct group admin count.
- `can_admin`: whether the current request user can administer the group, including inherited group admin rights and system admin override.

Group input accepts:

- `user_ids`: direct group member user IDs.
- `admin_user_ids`: direct group admin user IDs.

Omitted fields preserve existing state:

- If `user_ids` is omitted, current members are preserved.
- If `admin_user_ids` is omitted, current admin flags are preserved.

Invalid group admin updates return `422` with errors attached to `admin_user_ids`.

## Invariants

- A direct group admin must also be a direct group member.
- Removing a member also removes that user's admin flag for the same group.
- The final direct admin of a group cannot be removed.
- The final direct admin of a group cannot be demoted to a non-admin member.
- Deleting an entire group is allowed to destroy its memberships without triggering the final-admin guard.
- System admin authorization does not replace the need for at least one direct admin membership on each group.
- Existing group admin rights inherit to descendant groups through the group hierarchy.

## Bootstrap

`db/seeds.rb` is idempotent. When no system admin exists, seeds creates or promotes `root@example.org` to system admin, assigns a random password, and prints that password to the console for first-time initialization. If a system admin already exists, seeds leaves credentials unchanged and prints no password.

## Implementation Checklist

When adding or changing protected behavior:

- Decide whether the operation is read/collaboration or administration.
- Use member-based access for reads and board/task collaboration unless the operation changes group or project metadata.
- Use group admin checks for group management, subgroup creation, member/admin configuration, and project metadata mutations.
- Preserve the system admin override for administrative operations.
- Add request or policy coverage for system admin, inherited group admin, direct group admin, ordinary member, and unauthorized user cases.
- Add model coverage when changing direct admin invariants.
- Do not rely on frontend hiding as an authorization boundary.
