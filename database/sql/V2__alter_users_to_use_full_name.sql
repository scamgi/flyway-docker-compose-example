-- We add the new column first, making it nullable for now so we can handle existing data.
ALTER TABLE users ADD COLUMN full_name VARCHAR(201);

-- Here you would typically populate the new column based on the old ones.
-- For example: UPDATE users SET full_name = first_name || ' ' || last_name;
-- Since our table is likely empty in this tutorial, we can skip this update step.

-- Now, we can remove the old columns.
ALTER TABLE users
  DROP COLUMN first_name,
  DROP COLUMN last_name;

-- Finally, we make the new column NOT NULL, as it is a required field.
ALTER TABLE users ALTER COLUMN full_name SET NOT NULL;