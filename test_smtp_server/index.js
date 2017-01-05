process.title = 'test_smtp';

var onAuth = function(auth, session, callback) {
    if (auth.method === 'PLAIN') {
        if(auth.username !== 'foo@bar.com' || auth.password !== 'password'){
            return callback(new Error('Invalid username or password'));
        }
        callback(null, {user: 1});
    } else if (auth.method === 'LOGIN') {
        if(auth.username !== 'foo@bar.com' || auth.password !== 'password'){
            return callback(new Error('Invalid username or password'));
        }
        callback(null, {user: 1});
    } else if (auth.method === 'CRAM-MD5') {
        if(auth.username !== 'foo@bar.com' || !auth.validatePassword('password')){
            return callback(new Error('Invalid username or password'));
        }
        callback(null, {user: 1});
    } else if (auth.method === 'XOAUTH2') {
        if(auth.username !== 'foo@bar.com' || auth.accessToken !== 'password'){
            return callback(null, {
                data: {
                    status: '401',
                    schemes: 'bearer mac',
                    scope: 'my_smtp_access_scope_name'
                }
            });
        }
        callback(null, {user: 1});
    }
};

var SMTPServer = require('smtp-server').SMTPServer;
var server = new SMTPServer({
    disabledCommands: ['STARTTLS'],
    authMethods: ['PLAIN', 'LOGIN', 'XOAUTH2', 'CRAM-MD5'],
    onAuth: onAuth,
    onData: function(stream, session, callback){
        stream.pipe(process.stdout); // print message to console 
        stream.on('end', callback);
    }
});
server.listen(25);