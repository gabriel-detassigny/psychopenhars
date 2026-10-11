<?php
/**
 * Dump the WordPress tables to a gzipped SQL file using $wpdb only, for hosts
 * where WP-CLI has no mysqldump binary (e.g. OVH shared hosting).
 *
 * Usage: wp eval-file scripts/db-dump.php /path/to/db.sql.gz
 *
 * Output has exactly one SQL statement per line, which scripts/db-restore.php
 * relies on.
 *
 * @package psychopenhars
 */

global $wpdb;

$out = $args[0] ?? '';
if ( '' === $out ) {
	WP_CLI::error( 'Usage: wp eval-file scripts/db-dump.php <file.sql.gz>' );
}

$fh = gzopen( $out, 'wb6' );
if ( ! $fh ) {
	WP_CLI::error( "Cannot write $out" );
}

$dbh    = $wpdb->dbh;
$tables = $wpdb->get_col( $wpdb->prepare( 'SHOW TABLES LIKE %s', $wpdb->esc_like( $wpdb->prefix ) . '%' ) );

gzwrite( $fh, '-- psychopenhars db dump ' . gmdate( 'c' ) . ' server ' . $wpdb->db_server_info() . "\n" );
gzwrite( $fh, "SET NAMES utf8mb4;\nSET FOREIGN_KEY_CHECKS=0;\n" );

$total = 0;
foreach ( $tables as $table ) {
	$create = $wpdb->get_row( "SHOW CREATE TABLE `$table`", ARRAY_N );
	gzwrite( $fh, "DROP TABLE IF EXISTS `$table`;\n" );
	gzwrite( $fh, preg_replace( '/\s*\n\s*/', ' ', $create[1] ) . ";\n" );

	$offset = 0;
	do {
		$rows = $wpdb->get_results( "SELECT * FROM `$table` LIMIT $offset, 500", ARRAY_A );
		if ( ! $rows ) {
			break;
		}
		$cols   = '`' . implode( '`,`', array_keys( $rows[0] ) ) . '`';
		$values = array();
		foreach ( $rows as $row ) {
			$cells = array();
			foreach ( $row as $value ) {
				$cells[] = null === $value ? 'NULL' : "'" . mysqli_real_escape_string( $dbh, $value ) . "'";
			}
			$values[] = '(' . implode( ',', $cells ) . ')';
		}
		gzwrite( $fh, "INSERT INTO `$table` ($cols) VALUES " . implode( ',', $values ) . ";\n" );
		$total  += count( $rows );
		$offset += 500;
	} while ( count( $rows ) === 500 );
}

gzwrite( $fh, "SET FOREIGN_KEY_CHECKS=1;\n" );
gzclose( $fh );

WP_CLI::success( sprintf( 'Dumped %d tables, %d rows to %s', count( $tables ), $total, $out ) );
