<?php
/**
 * Plugin Name: Local environment constants
 * Description: Marks this Docker stack as a local environment.
 */

declare(strict_types=1);

if (! defined('WP_ENVIRONMENT_TYPE')) {
    define('WP_ENVIRONMENT_TYPE', 'local');
}
