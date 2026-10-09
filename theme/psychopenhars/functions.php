<?php
/**
 * Psychopenhars child theme.
 *
 * @package psychopenhars
 */

add_action(
	'init',
	static function () {
		register_block_pattern_category(
			'psychopenhars',
			array( 'label' => __( 'Cabinet', 'psychopenhars' ) )
		);
	}
);

add_action(
	'wp_enqueue_scripts',
	static function () {
		wp_enqueue_style(
			'psychopenhars',
			get_stylesheet_uri(),
			array(),
			wp_get_theme()->get( 'Version' )
		);
	}
);
