-- Trigger to automatically update waiting list when a ticket is cancelled
CREATE OR REPLACE FUNCTION ticket_cancel_trigger()
RETURNS TRIGGER AS $$
DECLARE
    CLASS_LABEL VARCHAR;
BEGIN
    -- Call the existing procedure to process waiting list
    SELECT s.class INTO CLASS_LABEL FROM seats s
    WHERE s.seat_id = OLD.seat_id;

    CALL add_ticket_on_cancel(OLD.train_id, CLASS_LABEL);
    
    RETURN NULL;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_ticket_cancel
AFTER DELETE ON tickets
FOR EACH ROW
EXECUTE FUNCTION ticket_cancel_trigger();

-- Trigger to ensure train capacity isn't exceeded
CREATE OR REPLACE FUNCTION check_train_capacity()
RETURNS TRIGGER AS $$
DECLARE
    max_seats INTEGER;
    current_bookings INTEGER;
BEGIN
    -- Get train capacity
    SELECT num_seats INTO max_seats FROM trains WHERE train_id = NEW.train_id;
    
    -- Count current bookings for this train on this date
    SELECT COUNT(*) INTO current_bookings 
    FROM tickets 
    WHERE train_id = NEW.train_id AND day_of_ticket = NEW.day_of_ticket;
    
    -- Check if adding this ticket would exceed capacity
    IF current_bookings >= max_seats THEN
        RAISE EXCEPTION 'Train capacity exceeded for train ID % on %', 
                        NEW.train_id, NEW.day_of_ticket;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_ticket_insert
BEFORE INSERT ON tickets
FOR EACH ROW
EXECUTE FUNCTION check_train_capacity();


CREATE OR REPLACE FUNCTION log_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (table_name, operation, record_id, old_data)
        VALUES (TG_TABLE_NAME, TG_OP, OLD.ticket_id, row_to_json(OLD)::jsonb);
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (table_name, operation, record_id, old_data, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.ticket_id, row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (table_name, operation, record_id, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.ticket_id, row_to_json(NEW)::jsonb);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tickets_audit
AFTER INSERT OR UPDATE OR DELETE ON tickets
FOR EACH ROW
EXECUTE FUNCTION log_changes();

-- Trigger to automatically generate payments when tickets are confirmed
-- CREATE OR REPLACE FUNCTION auto_payment_trigger()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     -- Only generate payment if one doesn't already exist
--     IF NOT EXISTS (SELECT 1 FROM payments WHERE ticket_id = NEW.ticket_id) THEN
--         -- Call the payment procedure with a default payment method
--         CALL PAY(NEW.ticket_id, 'Pending Payment');
--     END IF;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER after_ticket_insert
-- AFTER INSERT ON tickets
-- FOR EACH ROW
-- EXECUTE FUNCTION auto_payment_trigger();

CREATE OR REPLACE FUNCTION validate_ticket_id_exists()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tickets WHERE ticket_id = NEW.ticket_id) THEN
        RETURN NEW;
    ELSIF EXISTS (SELECT 1 FROM waiting_list WHERE ticket_id = NEW.ticket_id) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Invalid ticket_id: % not found in tickets or waiting_list', NEW.ticket_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_ticket_id
BEFORE INSERT ON payments
FOR EACH ROW
EXECUTE FUNCTION validate_ticket_id_exists();

