process.title = 'test_smtp';

var SMTPServer = require('smtp-server').SMTPServer;
var server = new SMTPServer({
    disabledCommands: ['STARTTLS'],
    authMethods: ['PLAIN', 'LOGIN', 'XOAUTH2', 'CRAM-MD5']
});
server.listen(25);