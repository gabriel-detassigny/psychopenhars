<?php
/**
 * Title: Accueil — bandeau
 * Slug: psychopenhars/hero
 * Categories: psychopenhars, banner
 * Description: Bandeau d’accueil avec photo de Quimper, présentation et bouton de rendez-vous.
 *
 * @package psychopenhars
 */

?>
<!-- wp:cover {"url":"/wp-content/uploads/2023/08/quimper.jpg","dimRatio":60,"overlayColor":"accent-3","isUserOverlayColor":true,"focalPoint":{"x":0.5,"y":0.6},"minHeight":520,"contentPosition":"center left","align":"full","style":{"spacing":{"padding":{"top":"var:preset|spacing|70","bottom":"var:preset|spacing|70","left":"var:preset|spacing|50","right":"var:preset|spacing|50"}}},"layout":{"type":"constrained"}} -->
<div class="wp-block-cover alignfull has-custom-content-position is-position-center-left" style="padding-top:var(--wp--preset--spacing--70);padding-right:var(--wp--preset--spacing--50);padding-bottom:var(--wp--preset--spacing--70);padding-left:var(--wp--preset--spacing--50);min-height:520px"><img class="wp-block-cover__image-background" alt="" src="/wp-content/uploads/2023/08/quimper.jpg" style="object-position:50% 60%" data-object-fit="cover" data-object-position="50% 60%"/><span aria-hidden="true" class="wp-block-cover__background has-accent-3-background-color has-background-dim-60 has-background-dim"></span><div class="wp-block-cover__inner-container">
	<!-- wp:group {"align":"wide","layout":{"type":"constrained","contentSize":"640px","justifyContent":"left"}} -->
	<div class="wp-block-group alignwide">
		<!-- wp:paragraph {"style":{"typography":{"textTransform":"uppercase","letterSpacing":"0.12em","fontWeight":"600"}},"textColor":"base","fontSize":"small"} -->
		<p class="has-base-color has-text-color has-small-font-size" style="font-weight:600;letter-spacing:0.12em;text-transform:uppercase">Cabinet de psychologues · Quimper</p>
		<!-- /wp:paragraph -->

		<!-- wp:heading {"level":1,"textColor":"base","fontSize":"xx-large"} -->
		<h1 class="wp-block-heading has-base-color has-text-color has-xx-large-font-size">Bonjour et bienvenue</h1>
		<!-- /wp:heading -->

		<!-- wp:paragraph {"textColor":"base","fontSize":"large"} -->
		<p class="has-base-color has-text-color has-large-font-size">Alice Reutlinger et Gwennaïg Le Nouy, psychologues cliniciennes, vous reçoivent en consultation sur rendez-vous.</p>
		<!-- /wp:paragraph -->

		<!-- wp:buttons {"style":{"spacing":{"margin":{"top":"var:preset|spacing|40"}}}} -->
		<div class="wp-block-buttons" style="margin-top:var(--wp--preset--spacing--40)">
			<!-- wp:button {"backgroundColor":"base","textColor":"accent-3"} -->
			<div class="wp-block-button"><a class="wp-block-button__link has-accent-3-color has-base-background-color has-text-color has-background wp-element-button" href="/contact/">Prendre rendez-vous</a></div>
			<!-- /wp:button -->
			<!-- wp:button {"className":"is-style-outline","textColor":"base"} -->
			<div class="wp-block-button is-style-outline"><a class="wp-block-button__link has-base-color has-text-color wp-element-button" href="#psychologues">Découvrir le cabinet</a></div>
			<!-- /wp:button -->
		</div>
		<!-- /wp:buttons -->
	</div>
	<!-- /wp:group -->
</div></div>
<!-- /wp:cover -->
