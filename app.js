const { exec, spawn } = require('child_process');
const fs = require('fs');
const express = require('express')
var session = require('express-session')
const cookieParser =  require('cookie-parser');
const app = express()
const port = 3000
const path = require('path')
app.use('/', express.static('static'))
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(session({ secret: 'terraformy', saveUninitialized: true, resave: true, cookie: { maxAge: 6000000 }}));
app.use(cookieParser());

var envplan={};
envplan.nodecount=3;
envplan.regions=[];
envplan.regions.push('US-East-1');
envplan.regions.push('US-East-2');
envplan.regions.push('US-West-2');
var sess;

app.post('/setPemPath', (req, res) => {
  sess=req.session;
  sess.pempath=req.body.pempath;
  sess.save();
  res.send(sess.pempath)
});

app.get('/getResources', (req, res) => {
    const data = fs.readFileSync('./tf_out.json', {encoding:'utf8'});
    var dataJSON=JSON.parse(data);
    var resources=dataJSON.values.root_module.resources;
    if (sess) {
      console.log(sess.pempath)
      resources.push({'pempath': sess.pempath})
    } else {
      console.log('no sess.pempath')
    }
    
    res.send(JSON.stringify(resources))
})

app.post('/killEC2', (req, res) => {
  if (sess.pempath===undefined) {
    console.log('dont have a pempath :(')
  } else {
    const ssh_stop = spawn("ssh", ["-i",sess.pempath,"ec2-user@"+req.body.ssh_ip,"sudo systemctl stop redpanda"])

    ssh_stop.stdout.on('data', (data) => {
      if (data==='child process exited with code 0') {
        res.send('something wrong: '+data);
      }
    });
    
    ssh_stop.stderr.on('data', (data) => {
      res.send('errored',data);
    });
    
    ssh_stop.on('close', (code) => {
      console.log(`successfully killed`);
      res.send('killed');
    }); 
  }
  
})

app.post('/startEC2', (req, res) => {
  if (sess.pempath===undefined) {
    console.log('dont have a pempath :(')
  } else {

    const ssh_stop = spawn("ssh", ["-i",sess.pempath,"ec2-user@"+req.body.ssh_ip,"sudo systemctl start redpanda"])

    ssh_stop.stdout.on('data', (data) => {
      if (data==='child process exited with code 0') {
        res.send('something wrong: '+data);
      }
    });
    
    ssh_stop.stderr.on('data', (data) => {
      res.send('errored',data);
    });
    
    ssh_stop.on('close', (code) => {
      res.send('started');
    }); 
  }
})

var statuses=[];

app.post('/statusEC2', (req, res) => {
  console.log(req.body)
  console.log('sess pempath',sess.pempath)
  var ssh_ip = req.body.ssh_ip;
  if (sess.pempath===undefined) {
    console.log('dont have a pempath :(')
  } else {

    const ssh_stop = spawn("ssh", ["-i",sess.pempath,"ec2-user@"+req.body.ssh_ip,"sudo systemctl status redpanda"])

    ssh_stop.stdout.on('data', (data) => {
      if (statuses[ssh_ip]) {
        statuses[ssh_ip]=data;
      } else {
        statuses.push({[ssh_ip]: `${data}`})
      }
    });
    
    ssh_stop.stderr.on('data', (data) => {
      if (statuses[ssh_ip]) {
        statuses[ssh_ip]=data;
      } else {
        statuses.push({[ssh_ip]: `${data}`})
      }
    });
    
    ssh_stop.on('close', (code) => {
      res.send(statuses);
    }); 
  }
})

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})