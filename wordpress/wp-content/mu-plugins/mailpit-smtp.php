<?php
/**
 * Plugin Name: Mailpit SMTP
 * Description: Routes WordPress mail to Mailpit in the local Docker environment.
 */

declare(strict_types=1);

add_action('phpmailer_init', static function ($phpmailer): void {
    if (!defined('WP_ENVIRONMENT_TYPE') || WP_ENVIRONMENT_TYPE !== 'local') {
        return;
    }

    $phpmailer->isSMTP();
    $phpmailer->Host = 'mailpit';
    $phpmailer->Port = 1025;
    $phpmailer->SMTPAuth = false;
    $phpmailer->SMTPSecure = false;
    $phpmailer->SMTPAutoTLS = false;
});
