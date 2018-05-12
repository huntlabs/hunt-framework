


DROP DATABASE IF EXISTS `hunt_test`;
CREATE DATABASE IF NOT EXISTS `hunt_test` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin */;
USE `hunt_test`;



DROP TABLE IF EXISTS `p_menu`;
CREATE TABLE IF NOT EXISTS `p_menu` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET latin1 DEFAULT '0',
  `up_menu_id` int(11) DEFAULT '0',
  `perident` varchar(50) CHARACTER SET latin1 DEFAULT '0',
  `index` int(11) DEFAULT '0',
  `icon` varchar(50) CHARACTER SET latin1 DEFAULT '0',
  `status` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


/*!40000 ALTER TABLE `p_menu` DISABLE KEYS */;
INSERT INTO `p_menu` (`ID`, `name`, `up_menu_id`, `perident`, `index`, `icon`, `status`) VALUES
	(1, 'User', 0, 'user.edit', 0, 'fe-box', 0),
	(2, 'Role', 0, 'role.edit', 0, 'fe-box', 0),
	(3, 'Module', 0, 'module.edit', 0, 'fe-box', 0),
	(4, 'Permission', 0, 'permission.edit', 0, 'fe-box', 0),
	(5, 'Menu', 0, 'menu.edit', 0, 'fe-box', 0),
	(6, 'Manage User', 1, 'user.edit', 0, '0', 0),
	(7, 'Add User', 1, 'user.add', 0, '0', 0),
	(8, 'Manage Role', 2, 'role.edit', 0, '0', 0),
	(9, 'Add Role', 2, 'role.add', 0, '0', 0),
	(10, 'Manage Module', 3, 'module.edit', 0, '0', 0),
	(11, 'Add Module', 3, 'module.add', 0, '0', 0),
	(12, 'Manage Permission', 4, 'permission.edit', 0, '0', 0),
	(13, 'Add Permission', 4, 'permission.add', 0, '0', 0),
	(14, 'Manage Menu', 5, 'menu.edit', 0, '0', 0),
	(15, 'Add Menu', 5, 'menu.add', 0, '0', 0);
/*!40000 ALTER TABLE `p_menu` ENABLE KEYS */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
