CREATE TABLE IF NOT EXISTS public.audit_logs (
    id_log        SERIAL PRIMARY KEY,
    fecha_hora    TIMESTAMP DEFAULT NOW(),
    codigo_error  VARCHAR(10),
    mensaje_error TEXT,
    contexto      TEXT
);

CREATE OR REPLACE FUNCTION public.registrar_actividad_comentario(
    p_id_usuario     comentario.id_usuario%TYPE,       -- A.3: %TYPE
    p_id_publicacion comentario.id_publicacion%TYPE    -- A.3: %TYPE
)
RETURNS VOID
LANGUAGE plpgsql
VOLATILE
AS $$
BEGIN
    INSERT INTO public.reporte_publicacion (motivo, id_usuario, id_publicacion, ventana_revision)
    VALUES (
        'Auto-sistema: Registro de actividad de comentario',
        p_id_usuario,
        p_id_publicacion,
        tsrange(NOW()::timestamp, (NOW() + '1 hour'::interval)::timestamp)
    );
  
END;
$$;

-- Verificación audit_logs
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'audit_logs';
