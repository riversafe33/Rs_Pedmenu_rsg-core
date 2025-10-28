CREATE TABLE IF NOT EXISTS `user_peds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(64) DEFAULT NULL,
  `playerName` varchar(64) DEFAULT NULL,
  `ped` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `ped_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(64) DEFAULT NULL,
  `playerName` varchar(64) DEFAULT NULL,
  `ped` varchar(64) DEFAULT NULL,
  `status` enum('pending','approved','rejected') DEFAULT 'pending',
  PRIMARY KEY (`id`)
);
