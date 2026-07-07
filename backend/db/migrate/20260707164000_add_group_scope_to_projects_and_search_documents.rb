class AddGroupScopeToProjectsAndSearchDocuments < ActiveRecord::Migration[8.1]
  def up
    add_reference :projects, :group, null: true, foreign_key: true
    add_reference :search_documents, :group, null: true, foreign_key: true

    backfill_project_groups
    backfill_search_document_groups

    change_column_null :projects, :group_id, false
  end

  def down
    remove_reference :search_documents, :group, foreign_key: true
    remove_reference :projects, :group, foreign_key: true
  end

  private

  def backfill_project_groups
    execute <<~SQL
      DO $$
      DECLARE
        project_user_id bigint;
        assigned_group_id bigint;
      BEGIN
        FOR project_user_id IN
          SELECT DISTINCT user_id FROM projects WHERE group_id IS NULL
        LOOP
          SELECT group_id
          INTO assigned_group_id
          FROM group_memberships
          WHERE user_id = project_user_id
          ORDER BY created_at ASC, id ASC
          LIMIT 1;

          IF assigned_group_id IS NULL THEN
            INSERT INTO groups (name, description, created_at, updated_at)
            VALUES (
              'Personal workspace',
              'Automatically created for existing projects.',
              CURRENT_TIMESTAMP,
              CURRENT_TIMESTAMP
            )
            RETURNING id INTO assigned_group_id;

            INSERT INTO group_memberships (group_id, user_id, created_at, updated_at)
            VALUES (assigned_group_id, project_user_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
          END IF;

          UPDATE projects
          SET group_id = assigned_group_id
          WHERE user_id = project_user_id
            AND group_id IS NULL;
        END LOOP;
      END $$;
    SQL
  end

  def backfill_search_document_groups
    execute <<~SQL.squish
      UPDATE search_documents
      SET group_id = projects.group_id
      FROM projects
      WHERE search_documents.searchable_type = 'Project'
        AND search_documents.searchable_id = projects.id
    SQL

    execute <<~SQL.squish
      UPDATE search_documents
      SET group_id = projects.group_id
      FROM tasks
      JOIN projects ON projects.id = tasks.project_id
      WHERE search_documents.searchable_type = 'Task'
        AND search_documents.searchable_id = tasks.id
    SQL

    execute <<~SQL.squish
      UPDATE search_documents
      SET group_id = searchable_id
      WHERE searchable_type = 'Group'
    SQL
  end
end
