-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 05-03-2026 a las 16:45:17
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `biblioteca`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ActualizarSocio` (IN `p_numero` INT, IN `p_nueva_dir` VARCHAR(150), IN `p_nuevo_tel` VARCHAR(10))   BEGIN
    UPDATE tbl_socio 
    SET soc_direccion = p_nueva_dir, soc_telefono = p_nuevo_tel
    WHERE soc_numero = p_numero;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_BuscarLibroPorNombre` (IN `p_titulo` VARCHAR(150))   BEGIN
    SELECT * FROM tbl_libro 
    WHERE lib_titulo LIKE CONCAT('%', p_titulo, '%');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_EliminarLibro` (IN `p_isbn` BIGINT)   BEGIN
    IF (SELECT COUNT(*) FROM tbl_prestamo WHERE lib_copiaisbn = p_isbn) = 0 THEN
        DELETE FROM tbl_libro WHERE lib_isbn = p_isbn;
    ELSE
        SELECT 'No se puede eliminar: El libro tiene préstamos registrados.' AS Mensaje;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_InsertarSocio` (IN `p_numero` INT, IN `p_nombre` VARCHAR(45), IN `p_apellido` VARCHAR(45), IN `p_direccion` VARCHAR(150), IN `p_telefono` VARCHAR(10))   BEGIN
    INSERT INTO tbl_socio (soc_numero, soc_nombre, soc_apellido, soc_direccion, soc_telefono)
    VALUES (p_numero, p_nombre, p_apellido, p_direccion, p_telefono);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ListarLibrosPrestados` ()   BEGIN
    SELECT l.lib_titulo, s.soc_nombre, s.soc_apellido, p.pres_fechaPrestamo
    FROM tbl_libro l
    INNER JOIN tbl_prestamo p ON l.lib_isbn = p.lib_copiaisbn
    INNER JOIN tbl_socio s ON p.soc_copiaNumero = s.soc_numero;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_SociosYPrestamos` ()   BEGIN
    SELECT s.soc_nombre, s.soc_apellido, p.pres_id, p.pres_fechaPrestamo
    FROM tbl_socio s
    LEFT JOIN tbl_prestamo p ON s.soc_numero = p.soc_copiaNumero;
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_DiasPrestamo` (`p_isbn` BIGINT) RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE dias INT;
    -- Toma el último préstamo registrado para ese libro
    SELECT DATEDIFF(pres_fechaDevolucion, pres_fechaPrestamo) INTO dias
    FROM tbl_prestamo
    WHERE lib_copiaisbn = p_isbn
    ORDER BY pres_fechaPrestamo DESC LIMIT 1;
    RETURN dias;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_TotalSocios` () RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE total INT;
    SELECT COUNT(*) INTO total FROM tbl_socio;
    RETURN total;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auditoria`
--

CREATE TABLE `auditoria` (
  `id_audi` int(11) NOT NULL,
  `isbn_libro` bigint(20) DEFAULT NULL,
  `titulo_anterior` varchar(150) DEFAULT NULL,
  `genero_anterior` varchar(50) DEFAULT NULL,
  `paginas_anterior` int(11) DEFAULT NULL,
  `diasPrestamo_anterior` int(11) DEFAULT NULL,
  `titulo_nuevo` varchar(150) DEFAULT NULL,
  `genero_nuevo` varchar(50) DEFAULT NULL,
  `paginas_nuevo` int(11) DEFAULT NULL,
  `diasPrestamo_nuevo` int(11) DEFAULT NULL,
  `audi_fecha` datetime DEFAULT NULL,
  `audi_usuario` varchar(100) DEFAULT NULL,
  `audi_accion` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `audi_socio`
--

CREATE TABLE `audi_socio` (
  `id_audi` int(10) NOT NULL,
  `socNumero_audi` int(11) DEFAULT NULL,
  `socNombre_anterior` varchar(45) DEFAULT NULL,
  `socApellido_anterior` varchar(45) DEFAULT NULL,
  `socDireccion_anterior` varchar(255) DEFAULT NULL,
  `socTelefono_anterior` varchar(10) DEFAULT NULL,
  `socNombre_nuevo` varchar(45) DEFAULT NULL,
  `socApellido_nuevo` varchar(45) DEFAULT NULL,
  `socDireccion_nuevo` varchar(255) DEFAULT NULL,
  `socTelefono_nuevo` varchar(10) DEFAULT NULL,
  `audi_fechaModificacion` datetime DEFAULT NULL,
  `audi_usuario` varchar(10) DEFAULT NULL,
  `audi_accion` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `entrada`
--

CREATE TABLE `entrada` (
  `entradaID` int(11) NOT NULL,
  `fechaEntrada` date NOT NULL,
  `cantidadEntrada` int(11) NOT NULL,
  `productoID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `entrada`
--

INSERT INTO `entrada` (`entradaID`, `fechaEntrada`, `cantidadEntrada`, `productoID`) VALUES
(1, '2020-10-06', 10, 1),
(2, '2020-10-06', 13, 1),
(3, '2020-10-06', 50, 2);

--
-- Disparadores `entrada`
--
DELIMITER $$
CREATE TRIGGER `entrada_producto` BEFORE INSERT ON `entrada` FOR EACH ROW BEGIN
    UPDATE Producto 
    SET cantidadTotalPro=Producto.cantidadTotalPro+new.cantidadEntrada
    WHERE new.productoID=Producto.productoID;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `productoID` int(11) NOT NULL,
  `nombrePro` varchar(30) NOT NULL,
  `precioPro` int(11) NOT NULL,
  `cantidadTotalPro` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`productoID`, `nombrePro`, `precioPro`, `cantidadTotalPro`) VALUES
(1, 'Panela', 200, 23),
(2, 'Pastas doria familiar', 3500, 50);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_autor`
--

CREATE TABLE `tbl_autor` (
  `aut_codigo` int(11) NOT NULL,
  `aut_apellido` varchar(45) NOT NULL,
  `aut_nacimiento` date DEFAULT NULL,
  `aut_muerte` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_autor`
--

INSERT INTO `tbl_autor` (`aut_codigo`, `aut_apellido`, `aut_nacimiento`, `aut_muerte`) VALUES
(98, 'Smith', '1974-12-21', '2018-07-21'),
(123, 'Taylor', '1980-04-15', NULL),
(234, 'Medina', '1977-06-21', '2005-09-12'),
(345, 'Wilson', '1975-08-29', NULL),
(432, 'Miller', '1981-10-26', NULL),
(456, 'García', '1978-09-27', '2021-12-09'),
(567, 'Davis', '1983-03-04', '2010-03-28'),
(678, 'Silva', '1986-02-02', NULL),
(765, 'López', '1976-07-08', '2022-05-10'),
(789, 'Rodríguez', '1985-12-10', NULL),
(890, 'Brown', '1982-11-17', NULL),
(901, 'Soto', '1979-05-13', '2015-11-05');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_libro`
--

CREATE TABLE `tbl_libro` (
  `lib_isbn` bigint(20) NOT NULL,
  `lib_titulo` varchar(150) NOT NULL,
  `lib_genero` varchar(50) DEFAULT NULL,
  `lib_numeroPaginas` int(11) DEFAULT NULL,
  `lib_diasPrestamo` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_libro`
--

INSERT INTO `tbl_libro` (`lib_isbn`, `lib_titulo`, `lib_genero`, `lib_numeroPaginas`, `lib_diasPrestamo`) VALUES
(1234567890, 'El Sueño de los Susurros', 'novela', 275, 7),
(1357924680, 'El Jardín de las Mariposas Perdidas', 'novela', 536, 7),
(2468135790, 'La Melodía de la Oscuridad', 'romance', 189, 7),
(2718281828, 'El Bosque de los Suspiros', 'novela', 387, 2),
(3141592653, 'El Secreto de las Estrellas Olvidadas', 'Misterio', 203, 7),
(5555555555, 'La Última Llave del Destino', 'cuento', 503, 7),
(7777777777, 'El Misterio de la Luna Plateada', 'Misterio', 422, 7),
(8642097531, 'El Reloj de Arena Infinito', 'novela', 321, 7),
(8888888888, 'La Ciudad de los Susurros', 'Misterio', 274, 1),
(9517530862, 'Las Crónicas del Eco Silencioso', 'fantasía', 448, 7),
(9876543210, 'El Laberinto de los Recuerdos', 'cuento', 412, 7),
(9999999999, 'El Enigma de los Espejos Rotos', 'romance', 156, 7);

--
-- Disparadores `tbl_libro`
--
DELIMITER $$
CREATE TRIGGER `auditoria_insert` AFTER INSERT ON `tbl_libro` FOR EACH ROW BEGIN
INSERT INTO audi_libro(
isbn_libro,
titulo_nuevo,
genero_nuevo,
paginas_nuevo,
diasPrestamo_nuevo,
audi_fecha,
audi_usuario,
audi_accion
)
VALUES(
NEW.lib_isbn,
NEW.lib_titulo,
NEW.lib_genero,
NEW.lib_numeroPaginas,
NEW.lib_diasPrestamo,
NOW(),USER(),
'Insert'
);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `delete_libro` BEFORE DELETE ON `tbl_libro` FOR EACH ROW BEGIN
INSERT INTO audi_libro(
isbn_libro,
titulo_anterior,
genero_anterior,
paginas_anterior,
diasPrestamo_anterior,
audi_fecha,
audi_usuario,
audi_accion
)
VALUES(
OLD.lib_isbn,
OLD.lib_titulo,
OLD.lib_genero,
OLD.lib_numeroPaginas,
OLD.lib_diasPrestamo,
NOW(),USER(),
'Delete'
);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `libro_update` BEFORE UPDATE ON `tbl_libro` FOR EACH ROW BEGIN
INSERT INTO audi_libro(
isbn_libro,
titulo_anterior,
genero_anterior,
paginas_anterior,
diasPrestamo_anterior,
titulo_nuevo,
genero_nuevo,
paginas_nuevo,
diasPrestamo_nuevo,
audi_fecha,
audi_usuario,
audi_accion
)
VALUES(
OLD.lib_isbn,
OLD.lib_titulo,
OLD.lib_genero,
OLD.lib_numeroPaginas,
OLD.lib_diasPrestamo,
NEW.lib_titulo,
NEW.lib_genero,
NEW.lib_numeroPaginas,
NEW.lib_diasPrestamo,
NOW(),USER(),
'Update'
);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_prestamo`
--

CREATE TABLE `tbl_prestamo` (
  `pres_id` varchar(20) NOT NULL,
  `pres_fechaPrestamo` date NOT NULL,
  `pres_fechaDevolucion` date DEFAULT NULL,
  `soc_copiaNumero` int(11) DEFAULT NULL,
  `lib_copiaisbn` bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_prestamo`
--

INSERT INTO `tbl_prestamo` (`pres_id`, `pres_fechaPrestamo`, `pres_fechaDevolucion`, `soc_copiaNumero`, `lib_copiaisbn`) VALUES
('pres1', '2023-01-15', '2023-01-20', 1, 1234567890),
('pres2', '2023-02-03', '2023-02-04', 2, 9999999999),
('pres3', '2023-04-09', '2023-04-11', 6, 2718281828),
('pres4', '2023-06-14', '2023-06-15', 9, 8888888888),
('pres5', '2023-07-02', '2023-07-09', 10, 5555555555),
('pres6', '2023-08-19', '2023-08-26', 12, 5555555555),
('pres7', '2023-10-24', '2023-10-27', 3, 1357924680),
('pres8', '2023-11-11', '2023-11-12', 4, 9999999999);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_socio`
--

CREATE TABLE `tbl_socio` (
  `soc_numero` int(11) NOT NULL,
  `soc_nombre` varchar(45) NOT NULL,
  `soc_apellido` varchar(45) NOT NULL,
  `soc_direccion` varchar(150) DEFAULT NULL,
  `soc_telefono` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_socio`
--

INSERT INTO `tbl_socio` (`soc_numero`, `soc_nombre`, `soc_apellido`, `soc_direccion`, `soc_telefono`) VALUES
(1, 'Ana', 'Ruiz', 'Calle Primavera 123', '9123456780'),
(2, 'Andrés Felipe', 'Galindo Luna', 'Avenida del Sol 456', '2123456789'),
(3, 'Juan', 'González', 'Calle Principal 789', '2012345678'),
(4, 'María', 'Rodríguez', 'Carrera del Río 321', '3012345678'),
(5, 'Pedro', 'Martínez', 'Calle del Bosque 654', '1234567812'),
(6, 'Ana', 'López', 'Avenida Central 987', '6123456781'),
(7, 'Carlos', 'Sánchez', 'Calle de la Luna 234', '1123456781'),
(8, 'Laura', 'Ramírez', 'Carrera del Mar 567', '1312345678'),
(9, 'Luis', 'Hernández', 'Avenida de la Montaña 890', '6101234567'),
(10, 'Andrea', 'García', 'Calle del Sol 432', '1112345678'),
(11, 'Alejandro', 'Torres', 'Carrera del Oeste 765', '4951234567'),
(12, 'Sofia', 'Morales', 'Avenida del Mar 098', '5512345678');

--
-- Disparadores `tbl_socio`
--
DELIMITER $$
CREATE TRIGGER `socios_before_update` BEFORE UPDATE ON `tbl_socio` FOR EACH ROW INSERT INTO audi_socio(
    socNumero_audi,
    socNombre_anterior,
    socApellido_anterior,
    socDireccion_anterior,
    socTelefono_anterior,
    socNombre_nuevo,
    socApellido_nuevo,
    socDireccion_nuevo,
    socTelefono_nuevo,
    audi_fechaModificacion,
    audi_usuario,
    audi_accion)
VALUES(
    new.soc_numero,
    old.soc_nombre,
    old.soc_apellido,
    old.soc_direccion,
    old.soc_telefono,
    new.soc_nombre,
    new.soc_apellido,
    new.soc_direccion,
    new.soc_telefono,
    NOW(),
    CURRENT_USER(),
    'Actualización')
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_tipoautores`
--

CREATE TABLE `tbl_tipoautores` (
  `copiaisbn` bigint(20) NOT NULL,
  `copiaAutor` int(11) NOT NULL,
  `tipoAutor` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_tipoautores`
--

INSERT INTO `tbl_tipoautores` (`copiaisbn`, `copiaAutor`, `tipoAutor`) VALUES
(1234567890, 123, 'Autor'),
(1234567890, 456, 'Coautor'),
(1234567890, 890, 'Autor'),
(1357924680, 123, 'Traductor'),
(2468135790, 234, 'Autor'),
(2718281828, 789, 'Traductor'),
(3141592653, 901, 'Autor'),
(5555555555, 678, 'Autor'),
(7777777777, 765, 'Autor'),
(8642097531, 345, 'Autor'),
(8888888888, 234, 'Autor'),
(8888888888, 345, 'Coautor'),
(9517530862, 432, 'Autor'),
(9876543210, 567, 'Autor'),
(9999999999, 98, 'Autor');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `auditoria`
--
ALTER TABLE `auditoria`
  ADD PRIMARY KEY (`id_audi`);

--
-- Indices de la tabla `audi_socio`
--
ALTER TABLE `audi_socio`
  ADD PRIMARY KEY (`id_audi`);

--
-- Indices de la tabla `entrada`
--
ALTER TABLE `entrada`
  ADD PRIMARY KEY (`entradaID`),
  ADD KEY `productoID` (`productoID`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`productoID`);

--
-- Indices de la tabla `tbl_autor`
--
ALTER TABLE `tbl_autor`
  ADD PRIMARY KEY (`aut_codigo`);

--
-- Indices de la tabla `tbl_libro`
--
ALTER TABLE `tbl_libro`
  ADD PRIMARY KEY (`lib_isbn`);

--
-- Indices de la tabla `tbl_prestamo`
--
ALTER TABLE `tbl_prestamo`
  ADD PRIMARY KEY (`pres_id`),
  ADD KEY `soc_copiaNumero` (`soc_copiaNumero`),
  ADD KEY `lib_copiaisbn` (`lib_copiaisbn`);

--
-- Indices de la tabla `tbl_socio`
--
ALTER TABLE `tbl_socio`
  ADD PRIMARY KEY (`soc_numero`);

--
-- Indices de la tabla `tbl_tipoautores`
--
ALTER TABLE `tbl_tipoautores`
  ADD PRIMARY KEY (`copiaisbn`,`copiaAutor`),
  ADD KEY `copiaAutor` (`copiaAutor`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `auditoria`
--
ALTER TABLE `auditoria`
  MODIFY `id_audi` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `audi_socio`
--
ALTER TABLE `audi_socio`
  MODIFY `id_audi` int(10) NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `entrada`
--
ALTER TABLE `entrada`
  ADD CONSTRAINT `entrada_ibfk_1` FOREIGN KEY (`productoID`) REFERENCES `producto` (`productoID`);

--
-- Filtros para la tabla `tbl_prestamo`
--
ALTER TABLE `tbl_prestamo`
  ADD CONSTRAINT `tbl_prestamo_ibfk_1` FOREIGN KEY (`soc_copiaNumero`) REFERENCES `tbl_socio` (`soc_numero`),
  ADD CONSTRAINT `tbl_prestamo_ibfk_2` FOREIGN KEY (`lib_copiaisbn`) REFERENCES `tbl_libro` (`lib_isbn`);

--
-- Filtros para la tabla `tbl_tipoautores`
--
ALTER TABLE `tbl_tipoautores`
  ADD CONSTRAINT `tbl_tipoautores_ibfk_1` FOREIGN KEY (`copiaisbn`) REFERENCES `tbl_libro` (`lib_isbn`),
  ADD CONSTRAINT `tbl_tipoautores_ibfk_2` FOREIGN KEY (`copiaAutor`) REFERENCES `tbl_autor` (`aut_codigo`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
