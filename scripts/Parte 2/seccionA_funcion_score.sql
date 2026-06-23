CREATE OR REPLACE FUNCTION public.calcular_score_publicacion(
    p_id_publicacion publicacion.id_publicacion%TYPE
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE                                                 
AS $$
DECLARE
    v_score INTEGER;
BEGIN
    SELECT COALESCE(SUM(valor), 0)
    INTO v_score
    FROM voto_publicacion
    WHERE id_publicacion = p_id_publicacion;

    RETURN v_score;
END;
$$;
