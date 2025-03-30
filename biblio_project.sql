-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 30, 2025 at 05:45 PM
-- Wersja serwera: 10.4.32-MariaDB
-- Wersja PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `biblio project`
--

DELIMITER $$
--
-- Procedury
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `DodajWypozyczenie` (IN `p_id_uzytkownika` INT, IN `p_id_egzemplarza` INT)   BEGIN
    -- Sprawdzenie, czy użytkownik istnieje
    IF NOT EXISTS (SELECT 1 FROM Uzytkownicy WHERE id_uzytkownika = p_id_uzytkownika) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Użytkownik o podanym ID nie istnieje.';
    END IF;

    -- Sprawdzenie, czy egzemplarz istnieje
    IF NOT EXISTS (SELECT 1 FROM Egzemplarze WHERE id_egzemplarza = p_id_egzemplarza) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Egzemplarz o podanym ID nie istnieje.';
    END IF;

    -- Sprawdzenie, czy egzemplarz jest już wypożyczony
    IF EXISTS (SELECT 1 FROM Wypozyczenia WHERE id_egzemplarza = p_id_egzemplarza AND data_zwrotu IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Egzemplarz jest już wypożyczony.';
    END IF;

    -- Dodanie wypożyczenia
    INSERT INTO Wypozyczenia (id_uzytkownika, id_egzemplarza, data_wypozyczenia, data_zwrotu)
    VALUES (p_id_uzytkownika, p_id_egzemplarza, NOW(3), TIMESTAMPADD(MONTH, 1, NOW(3)));
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `dodaj_egzemplarz_do_ksiazki` (IN `p_id_ksiazki` INT)   BEGIN
    INSERT INTO Egzemplarze (id_ksiazki) VALUES (p_id_ksiazki);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `dodaj_uzytkownika` (IN `p_imie` NVARCHAR(50), IN `p_nazwisko` NVARCHAR(50), IN `p_email` NVARCHAR(100))   BEGIN
    INSERT INTO Uzytkownicy (imie, nazwisko, email) VALUES (p_imie, p_nazwisko, p_email);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pokaz_aktywne_wypozyczenia_uzytkownika` (IN `p_id_uzytkownika` INT)   BEGIN
    SELECT W.id_wypozyczenia, K.tytul, W.data_wypozyczenia, W.data_zwrotu
    FROM Wypozyczenia W
    JOIN Egzemplarze E ON W.id_egzemplarza = E.id_egzemplarza
    JOIN Ksiazki K ON E.id_ksiazki = K.id_ksiazki
    WHERE W.id_uzytkownika = p_id_uzytkownika AND W.data_zwrotu IS NULL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `wypozycz_ksiazke` (IN `p_id_uzytkownika` INT, IN `p_id_egzemplarza` INT)   BEGIN
    -- Sprawdzenie, czy egzemplarz jest dostępny
    IF EXISTS (SELECT 1 FROM Egzemplarze WHERE id_egzemplarza = p_id_egzemplarza AND status = 'Dostępny') THEN
        -- Dodanie wypożyczenia
        INSERT INTO Wypozyczenia (id_uzytkownika, id_egzemplarza, data_wypozyczenia)
        VALUES (p_id_uzytkownika, p_id_egzemplarza, NOW());

        -- Zmiana statusu egzemplarza na "Wypożyczony"
        UPDATE Egzemplarze
        SET status = 'Wypożyczony'
        WHERE id_egzemplarza = p_id_egzemplarza;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Egzemplarz jest już wypożyczony lub niedostępny';
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `aktywne_wypozyczenia`
--

CREATE TABLE `aktywne_wypozyczenia` (
  `id_wypozyczenia` int(11) NOT NULL,
  `tytul` varchar(255) DEFAULT NULL,
  `imie` varchar(50) DEFAULT NULL,
  `nazwisko` varchar(50) DEFAULT NULL,
  `data_wypozyczenia` date DEFAULT NULL,
  `data_zwrotu` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `autorzy`
--

CREATE TABLE `autorzy` (
  `id_autora` int(11) NOT NULL,
  `imie` varchar(50) NOT NULL,
  `nazwisko` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `czarna_lista`
--

CREATE TABLE `czarna_lista` (
  `imie` varchar(50) NOT NULL,
  `nazwisko` varchar(50) NOT NULL,
  `data_umieszczenia` date NOT NULL,
  `id_uzytkownikCL` int(11) NOT NULL,
  `email` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `egzemplarze`
--

CREATE TABLE `egzemplarze` (
  `id_egzemplarza` int(11) NOT NULL,
  `id_ksiazki` int(11) DEFAULT NULL,
  `status` varchar(50) DEFAULT 'Dostępny'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `kategorie`
--

CREATE TABLE `kategorie` (
  `id_kategorii` int(11) NOT NULL,
  `nazwa` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ksiazki`
--

CREATE TABLE `ksiazki` (
  `id_ksiazki` int(11) NOT NULL,
  `tytul` varchar(200) DEFAULT NULL,
  `autor` varchar(100) DEFAULT NULL,
  `rok_wydania` int(11) DEFAULT NULL,
  `id_serii` int(11) DEFAULT NULL,
  `id_kategorii` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ksiazki_do_kupienia`
--

CREATE TABLE `ksiazki_do_kupienia` (
  `id_nksiazki` int(11) NOT NULL,
  `nazwa_nksiazki` varchar(255) DEFAULT NULL,
  `autor` varchar(255) DEFAULT NULL,
  `data_wydania` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `serie`
--

CREATE TABLE `serie` (
  `id_serie` int(11) NOT NULL,
  `nazwa_serii` varchar(255) NOT NULL,
  `id_autora` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `statusywypozyczen`
--

CREATE TABLE `statusywypozyczen` (
  `id_statusu` int(11) NOT NULL,
  `opis` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `uzytkownicy`
--

CREATE TABLE `uzytkownicy` (
  `id_uzytkownika` int(11) NOT NULL,
  `imie` varchar(50) DEFAULT NULL,
  `nazwisko` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `data_dołączenia` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `vw_wszyscyuzytkownicy`
-- (See below for the actual view)
--
CREATE TABLE `vw_wszyscyuzytkownicy` (
`id_uzytkownika` int(11)
,`imie` varchar(50)
,`nazwisko` varchar(50)
,`email` varchar(100)
,`status` varchar(17)
);

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `vw_wszystkieksiazki`
-- (See below for the actual view)
--
CREATE TABLE `vw_wszystkieksiazki` (
`id` bigint(21)
,`tytul` varchar(255)
,`autor` varchar(255)
,`rok_wydania` int(11)
,`status` varchar(11)
);

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `vw_wyposazeniebiblioteki`
-- (See below for the actual view)
--
CREATE TABLE `vw_wyposazeniebiblioteki` (
`nazwa` varchar(200)
,`ilosc` bigint(21)
,`typ` varchar(11)
,`lokalizacja` varchar(100)
,`stan` varchar(20)
);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `wyposazenie`
--

CREATE TABLE `wyposazenie` (
  `id_wyposazenia` int(11) NOT NULL,
  `nazwa` varchar(100) NOT NULL,
  `ilosc` int(11) NOT NULL CHECK (`ilosc` >= 0),
  `lokalizacja` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `stan` varchar(20) NOT NULL CHECK (`stan` in ('Zniszczone','Używane','Nowe'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `wypozyczenia`
--

CREATE TABLE `wypozyczenia` (
  `id_wypozyczenia` int(11) NOT NULL,
  `id_uzytkownika` int(11) DEFAULT NULL,
  `id_egzemplarza` int(11) DEFAULT NULL,
  `data_wypozyczenia` datetime(3) DEFAULT current_timestamp(3),
  `data_zwrotu` datetime(3) DEFAULT NULL,
  `id_statusu` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktura widoku `vw_wszyscyuzytkownicy`
--
DROP TABLE IF EXISTS `vw_wszyscyuzytkownicy`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_wszyscyuzytkownicy`  AS SELECT `uzytkownicy`.`id_uzytkownika` AS `id_uzytkownika`, `uzytkownicy`.`imie` AS `imie`, `uzytkownicy`.`nazwisko` AS `nazwisko`, `uzytkownicy`.`email` AS `email`, 'Aktywny' AS `status` FROM `uzytkownicy`union select `czarna_lista`.`id_uzytkownikCL` AS `id_uzytkownika`,`czarna_lista`.`imie` AS `imie`,`czarna_lista`.`nazwisko` AS `nazwisko`,NULL AS `email`,'Na Czarnej Liście' AS `status` from `czarna_lista`  ;

-- --------------------------------------------------------

--
-- Struktura widoku `vw_wszystkieksiazki`
--
DROP TABLE IF EXISTS `vw_wszystkieksiazki`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_wszystkieksiazki`  AS SELECT `ksiazki`.`id_ksiazki` AS `id`, `ksiazki`.`tytul` AS `tytul`, `ksiazki`.`autor` AS `autor`, `ksiazki`.`rok_wydania` AS `rok_wydania`, 'Dostępna' AS `status` FROM `ksiazki`union all select row_number() over ( order by `ksiazki_do_kupienia`.`nazwa_nksiazki`) AS `id`,`ksiazki_do_kupienia`.`nazwa_nksiazki` AS `tytul`,`ksiazki_do_kupienia`.`autor` AS `autor`,year(`ksiazki_do_kupienia`.`data_wydania`) AS `rok_wydania`,'Do kupienia' AS `status` from `ksiazki_do_kupienia`  ;

-- --------------------------------------------------------

--
-- Struktura widoku `vw_wyposazeniebiblioteki`
--
DROP TABLE IF EXISTS `vw_wyposazeniebiblioteki`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_wyposazeniebiblioteki`  AS SELECT `k`.`tytul` AS `nazwa`, count(`e`.`id_egzemplarza`) AS `ilosc`, 'Książka' AS `typ`, NULL AS `lokalizacja`, NULL AS `stan` FROM (`ksiazki` `k` left join `egzemplarze` `e` on(`k`.`id_ksiazki` = `e`.`id_ksiazki`)) GROUP BY `k`.`tytul`union select `w`.`nazwa` AS `nazwa`,`w`.`ilosc` AS `ilosc`,'Wyposażenie' AS `typ`,`w`.`lokalizacja` AS `lokalizacja`,`w`.`stan` AS `stan` from `wyposazenie` `w`  ;

--
-- Indeksy dla zrzutów tabel
--

--
-- Indeksy dla tabeli `aktywne_wypozyczenia`
--
ALTER TABLE `aktywne_wypozyczenia`
  ADD PRIMARY KEY (`id_wypozyczenia`);

--
-- Indeksy dla tabeli `autorzy`
--
ALTER TABLE `autorzy`
  ADD PRIMARY KEY (`id_autora`);

--
-- Indeksy dla tabeli `czarna_lista`
--
ALTER TABLE `czarna_lista`
  ADD PRIMARY KEY (`id_uzytkownikCL`);

--
-- Indeksy dla tabeli `egzemplarze`
--
ALTER TABLE `egzemplarze`
  ADD PRIMARY KEY (`id_egzemplarza`),
  ADD KEY `id_ksiazki` (`id_ksiazki`);

--
-- Indeksy dla tabeli `kategorie`
--
ALTER TABLE `kategorie`
  ADD PRIMARY KEY (`id_kategorii`),
  ADD UNIQUE KEY `nazwa` (`nazwa`);

--
-- Indeksy dla tabeli `ksiazki`
--
ALTER TABLE `ksiazki`
  ADD PRIMARY KEY (`id_ksiazki`);

--
-- Indeksy dla tabeli `ksiazki_do_kupienia`
--
ALTER TABLE `ksiazki_do_kupienia`
  ADD PRIMARY KEY (`id_nksiazki`);

--
-- Indeksy dla tabeli `serie`
--
ALTER TABLE `serie`
  ADD PRIMARY KEY (`id_serie`),
  ADD KEY `id_autora` (`id_autora`);

--
-- Indeksy dla tabeli `statusywypozyczen`
--
ALTER TABLE `statusywypozyczen`
  ADD PRIMARY KEY (`id_statusu`),
  ADD UNIQUE KEY `opis` (`opis`);

--
-- Indeksy dla tabeli `uzytkownicy`
--
ALTER TABLE `uzytkownicy`
  ADD PRIMARY KEY (`id_uzytkownika`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indeksy dla tabeli `wyposazenie`
--
ALTER TABLE `wyposazenie`
  ADD PRIMARY KEY (`id_wyposazenia`);

--
-- Indeksy dla tabeli `wypozyczenia`
--
ALTER TABLE `wypozyczenia`
  ADD PRIMARY KEY (`id_wypozyczenia`),
  ADD KEY `id_uzytkownika` (`id_uzytkownika`),
  ADD KEY `id_egzemplarza` (`id_egzemplarza`),
  ADD KEY `id_statusu` (`id_statusu`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `aktywne_wypozyczenia`
--
ALTER TABLE `aktywne_wypozyczenia`
  MODIFY `id_wypozyczenia` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `czarna_lista`
--
ALTER TABLE `czarna_lista`
  MODIFY `id_uzytkownikCL` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `egzemplarze`
--
ALTER TABLE `egzemplarze`
  MODIFY `id_egzemplarza` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `kategorie`
--
ALTER TABLE `kategorie`
  MODIFY `id_kategorii` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ksiazki`
--
ALTER TABLE `ksiazki`
  MODIFY `id_ksiazki` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ksiazki_do_kupienia`
--
ALTER TABLE `ksiazki_do_kupienia`
  MODIFY `id_nksiazki` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `serie`
--
ALTER TABLE `serie`
  MODIFY `id_serie` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `statusywypozyczen`
--
ALTER TABLE `statusywypozyczen`
  MODIFY `id_statusu` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `uzytkownicy`
--
ALTER TABLE `uzytkownicy`
  MODIFY `id_uzytkownika` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `wyposazenie`
--
ALTER TABLE `wyposazenie`
  MODIFY `id_wyposazenia` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `wypozyczenia`
--
ALTER TABLE `wypozyczenia`
  MODIFY `id_wypozyczenia` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `egzemplarze`
--
ALTER TABLE `egzemplarze`
  ADD CONSTRAINT `egzemplarze_ibfk_1` FOREIGN KEY (`id_ksiazki`) REFERENCES `ksiazki` (`id_ksiazki`) ON DELETE CASCADE;

--
-- Constraints for table `serie`
--
ALTER TABLE `serie`
  ADD CONSTRAINT `serie_ibfk_1` FOREIGN KEY (`id_autora`) REFERENCES `autorzy` (`id_autora`);

--
-- Constraints for table `wypozyczenia`
--
ALTER TABLE `wypozyczenia`
  ADD CONSTRAINT `wypozyczenia_ibfk_1` FOREIGN KEY (`id_uzytkownika`) REFERENCES `uzytkownicy` (`id_uzytkownika`) ON DELETE CASCADE,
  ADD CONSTRAINT `wypozyczenia_ibfk_2` FOREIGN KEY (`id_egzemplarza`) REFERENCES `egzemplarze` (`id_egzemplarza`) ON DELETE CASCADE,
  ADD CONSTRAINT `wypozyczenia_ibfk_3` FOREIGN KEY (`id_statusu`) REFERENCES `statusywypozyczen` (`id_statusu`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
