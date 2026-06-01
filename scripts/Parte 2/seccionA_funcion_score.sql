-- Verificación
-- SELECT public.calcular_score_publicacion(1);

CREATE OR REPLACE FUNCTION public.calcular_score_publicacion(
    p_id_publicacion publicacion.id_publicacion%TYPE   
RETURNS INTEGER
LANGUAGE plpgsql
STABLE                                                  
AS $$
DECLARE
    v_votos_positivos INTEGER;
    v_votos_negativos INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_votos_positivos
    FROM voto_publicacion
    WHERE id_publicacion = p_id_publicacion
      AND valor = 1;

    SELECT COUNT(*)
    INTO v_votos_negativos
    FROM voto_publicacion
    WHERE id_publicacion = p_id_publicacion
      AND valor = -1;

    RETURN v_votos_positivos - v_votos_negativos;
END;
$$;

