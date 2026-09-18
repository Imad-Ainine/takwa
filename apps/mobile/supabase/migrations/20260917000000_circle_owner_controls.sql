-- Circle owner-control RPCs (Track B, home-feature-completeness spec)
--
-- Three SECURITY DEFINER functions that enforce server-side ownership checks
-- before mutating circle data. All three are called from SupabaseClientService
-- via .rpc(...) — no direct table writes from the client.
--
-- Error codes raised as Postgres exceptions are caught in SupabaseClientService
-- and rethrown as CircleOperationException(code).

-- rename_circle(circle_id uuid, new_name text)
-- Validates: caller must be owner; new_name must be 1–50 chars, non-whitespace-only.
CREATE OR REPLACE FUNCTION rename_circle(circle_id uuid, new_name text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF (SELECT owner_id FROM circles WHERE id = circle_id) <> auth.uid() THEN
    RAISE EXCEPTION 'not_owner';
  END IF;
  IF length(trim(new_name)) = 0 OR length(new_name) > 50 THEN
    RAISE EXCEPTION 'invalid_name';
  END IF;
  UPDATE circles SET name = new_name WHERE id = circle_id;
END;
$$;

-- delete_circle(circle_id uuid)
-- Deletes circle_members rows then the circle itself in one transaction.
-- Caller must be the owner.
CREATE OR REPLACE FUNCTION delete_circle(circle_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF (SELECT owner_id FROM circles WHERE id = circle_id) <> auth.uid() THEN
    RAISE EXCEPTION 'not_owner';
  END IF;
  DELETE FROM circle_members WHERE circle_id = delete_circle.circle_id;
  DELETE FROM circles WHERE id = circle_id;
END;
$$;

-- remove_circle_member(circle_id uuid, member_user_id uuid)
-- Caller must be the owner; the owner cannot remove themselves.
CREATE OR REPLACE FUNCTION remove_circle_member(circle_id uuid, member_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF (SELECT owner_id FROM circles WHERE id = circle_id) <> auth.uid() THEN
    RAISE EXCEPTION 'not_owner';
  END IF;
  IF member_user_id = auth.uid() THEN
    RAISE EXCEPTION 'cannot_remove_self';
  END IF;
  DELETE FROM circle_members
  WHERE circle_id = remove_circle_member.circle_id
    AND user_id = member_user_id;
END;
$$;
