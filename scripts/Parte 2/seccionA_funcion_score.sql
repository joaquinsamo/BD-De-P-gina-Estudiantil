-- =========================================================================
-- SECCIÓN A.1 / A.3
-- Función orientada a valores: calcula el score neto de una publicación.
-- Volatilidad STABLE: lee datos de la BD pero no los modifica,
-- y devuelve el mismo resultado para los mismos parámetros dentro
-- de una transacción → permite que el planificador cachee el resultado
-- sin sobrecarga innecesaria de CPU.
-- =========================================================================

CREATE OR REPLACE FUNCTION public.calcular_score_publicacion(
    p_id_publicacion publicacion.id_publicacion%TYPE   -- A.3: %TYPE en vez de INT estático
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE                                                  -- A.1: volatilidad correcta
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

-- Verificación rápida
-- SELECT public.calcular_score_publicacion(1);
