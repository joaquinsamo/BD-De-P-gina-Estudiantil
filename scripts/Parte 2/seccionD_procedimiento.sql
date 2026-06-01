CREATE OR REPLACE PROCEDURE public.crear_comentario_seguro(
    p_cuerpo         comentario.cuerpo%TYPE,
    p_id_usuario     comentario.id_usuario%TYPE,
    p_id_publicacion comentario.id_publicacion%TYPE,
    p_id_padre       comentario.id_comentario_padre%TYPE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_existe  usuario%ROWTYPE;
    v_pub_resuelta publicacion.esta_resuelto%TYPE;
    v_sqlstate     TEXT;
    v_msg          TEXT;
BEGIN
    SELECT * INTO v_user_existe
    FROM usuario
    WHERE id_usuario = p_id_usuario;

    IF NOT FOUND THEN
        INSERT INTO public.audit_logs (codigo_error, mensaje_error, contexto)
        VALUES (
            '42703',
            'Usuario inexistente',
            'Intento con ID: ' || p_id_usuario
        );
        RAISE EXCEPTION 'El usuario con ID % no existe.', p_id_usuario;
    END IF;

    SELECT esta_resuelto INTO v_pub_resuelta
    FROM publicacion
    WHERE id_publicacion = p_id_publicacion;

    IF v_pub_resuelta = TRUE THEN
        INSERT INTO public.audit_logs (codigo_error, mensaje_error, contexto)
        VALUES (
            'ERR_RES',
            'Intento de comentar en publicación resuelta',
            'ID Pub: ' || p_id_publicacion
        );
        RAISE EXCEPTION 'No se pueden añadir comentarios a una publicación ya resuelta.';
    END IF;

    INSERT INTO comentario (cuerpo, id_usuario, id_publicacion, id_comentario_padre)
    VALUES (p_cuerpo, p_id_usuario, p_id_publicacion, p_id_padre);

    BEGIN
        PERFORM public.registrar_actividad_comentario(p_id_usuario, p_id_publicacion);
    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                v_sqlstate = RETURNED_SQLSTATE,
                v_msg      = MESSAGE_TEXT;

            INSERT INTO public.audit_logs (codigo_error, mensaje_error, contexto)
            VALUES (
                v_sqlstate,
                v_msg,
                'Fallo controlado en subproceso registrar_actividad. '
                || 'El comentario principal fue insertado correctamente.'
            );
    END;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
$$;

CALL public.crear_comentario_seguro('Comentario de prueba seguro', 1, 1, NULL);

SELECT * FROM public.audit_logs ORDER BY fecha_hora DESC LIMIT 10;
