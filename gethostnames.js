'use strict';

const fs = require('fs');

let rawdata = fs.readFileSync('tf_out.json');
let tfout = JSON.parse(rawdata);
let resources = tfout.values.root_module.resources;
var ec2s=[];

var lasthostPub='';
var lasthostPriv='';
var hosts_ini='[redpanda]\r\n';
let ssh_user='ec2-user'
var node_id=0;
var prev_node_id=0;
var hostline='';

async function createRPsection() {
    resources.forEach(function(resource) {
    
        if (resource.values.public_dns && !ec2s.includes(ec2PubIp)) {
            hostline='';        
            var ec2PubIp=resource.values.public_ip;
            var ec2PrivIp=resource.values.private_ip;
            lasthostPub=ec2PubIp;
            lasthostPriv=ec2PrivIp;
            prev_node_id=node_id-1;
            hostline=ec2PubIp+' ansible_user='+ssh_user+' ansible_become=True private_ip='+ec2PrivIp+' id='+node_id+'\r\n'
            hosts_ini=hosts_ini+hostline
            ec2s.push(ec2PubIp);
            node_id=node_id+1;
        } 
    });
}

createRPsection()
.then(function() {
    //after redpanda section add [monitoring] section
    hosts_ini=hosts_ini+'\r\n[monitoring]\r\n'+hostline
})
.then(function() {
    console.log(hosts_ini)
    fs.writeFileSync('deployment-automation/hosts.ini',hosts_ini)
})

