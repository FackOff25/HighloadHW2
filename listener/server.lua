local socket = require("socket")
require("http.response")

Server = {
    host = "localhost",
    port = 80,
    connections = {},
    isOn = false,
    server = nil,
}

function Server:new()
    local serv = {};
    setmetatable(serv,self);

    self.__index = self;

    return serv;
end

---@param host string
---@param port number
function Server:start(host, port)
    host = host or "localhost";
    port = port or 80;
    
    local server, e = socket.bind(host, port);
    
    if server == nil then
        io.write(e.."\n");
        return nil;
    end

    self.server = server;
    local i, p = self.server:getsockname();
    self.host = i;
    self.port = p;
    self.isOn = true;

    while self.isOn do
        self:acceptClient();
        while #self.connections > 0 do
            local c = table.remove(self.connections);
            local data, e = c:receive();
            if e == "closed" then
                c:close();
                table.remove(self.connections, i);
            elseif data then
                local response = Response:new(200, {['Content-Type'] = "text/plain"}, "OK")
                c:send(response:makeResponseString())
                c:close();
            end
        end
    end
end

function Server:acceptClient()
    local conn = self.server:accept();
    if conn then
        table.insert(self.connections, conn);
    end
end

function Server:stop()
    for _, conn in pairs(self.connections) do
        conn.close();
    end
    self.server:stop();
    self.isOn = false;
end