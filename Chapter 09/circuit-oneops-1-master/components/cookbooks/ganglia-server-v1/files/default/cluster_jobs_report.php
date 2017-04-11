<?php

// CUSTOM REPORT
// This report displays custom metrics for a cluster.  The metrics
// included in this report are:
//
// cluster.jobs_running
//
/* graph_ goes here, not in the filename */
function graph_cluster_jobs_report ( &$rrdtool_graph ) {

    // pull in a number of global variables, many set in conf.php (such as colors)
    // but other from elsewhere, such as get_context.php
    global $conf,
           $context,
           $range,
           $rrd_dir,
           $size;

    // Clean the hostname
    if ($conf['strip_domainname']) {
       $hostname = strip_domainname($GLOBALS['hostname']);
    } else {
       $hostname = $GLOBALS['hostname'];
    }

    //
    // You *MUST* set at least the 'title', 'vertical-label', and 'series'
    // variables otherwise, the graph *will not work*.
    //
    $title = 'Jobs';
    if ($context != 'host') {
       //  This will be turned into: "Clustername $TITLE last $timerange",
       //  so keep it short
       $rrdtool_graph['title']  = $title;
    } else {
       $rrdtool_graph['title']  = "$hostname $title last $range";
    }

    $rrdtool_graph['vertical-label'] = 'Jobs';
    // Fudge to account for number of lines in the chart legend
    $rrdtool_graph['height']        += ($size == 'medium') ? 20 : 0;
    #$rrdtool_graph['upper-limit']    = '100';
    $rrdtool_graph['lower-limit']    = '0';
    $rrdtool_graph['extras']         = '--rigid';

    // --------------------------------
    // Graph Definition
    // -------------------------------
    $series = "";
    $series .= "DEF:'jobs'='${rrd_dir}/cluster.jobs_running.rrd':'sum':AVERAGE ";
    //$series .= "DEF:'users'='${rrd_dir}/cluster.unique_users.rrd':'sum':AVERAGE ";
    $series .= "LINE2:'jobs'#009999:'Jobs' ";
    //$series .= "LINE2:'users'#990099:'Users' ";


    // We have everything now, so add it to the array, and go on our way.
    $rrdtool_graph['series'] = $series;

    return $rrdtool_graph;
}

?>
