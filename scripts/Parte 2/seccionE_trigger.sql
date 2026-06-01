CREATE OR REPLACE FUNCTION public.trg_auditar_cambio_rol()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.id_rol IS DISTINCT FROM NEW.id_rol THEN
        INSERT INTO public.audit_logs (codigo_error, mensaje_error, contexto)
        VALUES (
            'DML_TRG',
            'Cambio de rol automático detectado',
            'Usuario: ' || NEW.nombre_usuario
            || ' | Rol anterior: ' || OLD.id_rol
            || ' | Rol nuevo: '    || NEW.id_rol
        );
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_cambio_rol ON usuario;

CREATE TRIGGER trigger_cambio_rol
    AFTER UPDATE ON usuario
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_auditar_cambio_rol();

UPDATE usuario
SET id_rol = CASE WHEN id_rol = 2 THEN 1 ELSE 2 END
WHERE id_usuario = 1;

SELECT *
FROM public.audit_logs
WHERE codigo_error = 'DML_TRG'
ORDER BY fecha_hora DESC
LIMIT 5;
