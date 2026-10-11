<?php
/**
 * Seeds the local wp-env site with the migrated content. Idempotent: pages
 * are matched by slug and updated in place.
 *
 * Run: npm run seed
 *
 * @package psychopenhars
 */

$content_dir = WP_CONTENT_DIR . '/psy-repo/content';
// Same IDs and slugs as production, so legacy URLs (?page_id=N,
// /index.php/<slug>/) resolve exactly as they will on the live site.
$pages = array(
	11  => array( 'cabinet-de-psychologues', 'Accueil', 'home.html' ),
	13  => array( 'contact', 'Contact & accès', 'contact.html' ),
	26  => array( 'alice-reutlinger', 'Alice Reutlinger, psychologue', 'alice-reutlinger.html' ),
	154 => array( 'gwennaig-le-nouy', 'Gwennaïg Le Nouy, psychologue', 'gwennaig-le-nouy.html' ),
);

foreach ( $pages as $id => list( $slug, $title, $file ) ) {
	// Drop copies created under another ID (e.g. by an older seed).
	$stale = get_page_by_path( $slug );
	if ( $stale && $stale->ID !== $id ) {
		wp_delete_post( $stale->ID, true );
	}
	$postarr = array(
		'post_type'    => 'page',
		'post_status'  => 'publish',
		'post_name'    => $slug,
		'post_title'   => $title,
		'post_content' => file_get_contents( "$content_dir/$file" ),
	);
	if ( get_post( $id ) ) {
		$postarr['ID'] = $id;
	} else {
		$postarr['import_id'] = $id;
	}
	$result = wp_insert_post( $postarr, true );
	if ( is_wp_error( $result ) || $result !== $id ) {
		WP_CLI::error( "Could not create page $id ($slug)." );
	}
}
foreach ( get_posts( array( 'name' => 'accueil', 'post_type' => 'page', 'post_status' => 'any' ) ) as $post ) {
	wp_delete_post( $post->ID, true );
}

// Default install content that the live site doesn't have.
foreach ( array( 'sample-page', 'hello-world' ) as $slug ) {
	foreach ( get_posts( array( 'name' => $slug, 'post_type' => array( 'post', 'page' ), 'post_status' => 'any' ) ) as $post ) {
		wp_delete_post( $post->ID, true );
	}
}

update_option( 'show_on_front', 'page' );
update_option( 'page_on_front', 11 );
update_option( 'blogname', 'Cabinet de psychologues' );
update_option( 'blogdescription', 'Psychologues à Quimper' );
update_option( 'WPLANG', '' );
switch_theme( 'psychopenhars' );
update_option( 'permalink_structure', '/%postname%/' );
flush_rewrite_rules( false );

WP_CLI::success( 'Seeded pages: ' . implode( ', ', array_keys( $pages ) ) );
