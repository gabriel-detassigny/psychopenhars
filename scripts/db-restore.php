<?php
/**
 * Restore a dump made by scripts/db-dump.php (one statement per line), for
 * hosts where WP-CLI has no mysql client binary.
 *
 * Usage: wp eval-file scripts/db-restore.php /path/to/db.sql.gz --skip-plugins --skip-themes
 *
 * @package psychopenhars
 */

global $wpdb;

$in = $args[0] ?? '';
$fh = $in ? gzopen( $in, 'rb' ) : false;
if ( ! $fh ) {
	WP_CLI::error( 'Usage: wp eval-file scripts/db-restore.php <file.sql.gz>' );
}

$dbh   = $wpdb->dbh;
$count = 0;
while ( ! gzeof( $fh ) ) {
	$line = rtrim( (string) gzgets( $fh ), "\n" );
	if ( '' === $line || str_starts_with( $line, '--' ) ) {
		continue;
	}
	if ( ! mysqli_query( $dbh, $line ) ) {
		WP_CLI::error( 'Statement failed: ' . mysqli_error( $dbh ) . ' — ' . substr( $line, 0, 120 ) );
	}
	++$count;
}
gzclose( $fh );

WP_CLI::success( "Executed $count statements from $in" );
