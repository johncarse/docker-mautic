<?php

/*
 * Build-time runtime probe: exercises PRedisConnectionHelper against a real
 * Redis exactly the way the app does at runtime — parse the URL, resolve the
 * host, build options, construct the Predis client, ping.
 *
 * Exists because of the 2026-09-09 incident: a rebase dropped the
 * single-endpoint unwrap hunk and every Redis-backed request threw
 * "Array of connection parameters requires `cluster`, `replication` or
 * `aggregate` client option" — at runtime only. cache:warmup cannot catch
 * that; this does, before the image is pushed.
 */

require '/var/www/html/vendor/autoload.php';

use Mautic\CoreBundle\Helper\PRedisConnectionHelper;

$url = getenv('PROBE_REDIS_URL') ?: 'redis://localhost:6379';

$endpoints = PRedisConnectionHelper::getRedisEndpoints($url);
$endpoints = is_array($endpoints) ? $endpoints : iterator_to_array($endpoints);
$options   = PRedisConnectionHelper::makeRedisOptions(['url' => $url], 'probe:');

$client = PRedisConnectionHelper::createClient($endpoints, $options);
$pong   = $client->ping();

if ('PONG' !== (string) $pong) {
    fwrite(STDERR, 'unexpected ping response: '.var_export($pong, true)."\n");
    exit(1);
}

echo 'redis probe OK — endpoints: '.json_encode($endpoints)."\n";
