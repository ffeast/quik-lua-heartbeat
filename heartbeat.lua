--[[
QUIK https://arqatech.com/ru/products/quik/ lua hearbeat script
When the script is running from inside QUIK it would constantly write metrics with session parameters
This file can be further picked up by a monitoring tool for further analysis / alerting

Nice README, questions & fixes: https://github.com/ffeast/quik-lua-heartbeat
Just put this script into C:\QuikPath\lua folder and run it to start writing metrics
--]]

-- where to save the metrics file. Feel free to set any path you want
METRICS_PATH = getScriptPath() .. '\\metrics\\metrics.txt'
-- delay between metrics writes. Set a lower value to write metrics more often
SLEEP_PERIOD_MSEC = 60 * 1000
-- the metrics file will be rewritten after this number of write_metrics call
-- to prevent infinite metrics file growth
REWRITE_EVERY_N_RECORDS = 1000
-- number of attempts to open the file
MAX_WRITE_ATTEMPTS = 10

function write_metrics(metrics, counter)
    local mode
    if counter % REWRITE_EVERY_N_RECORDS == 0 then
        mode = 'w'
    else
        mode = 'a'
    end

    local file
    local tries = 0
    while tries < MAX_WRITE_ATTEMPTS do
        file = io.open(METRICS_PATH, mode)
        if file ~= nil then
            break
        end
        tries = tries + 1
    end
    if file == nil then
        error('Unable to open '
              .. METRICS_PATH
              .. ' in mode "' .. tostring(mode) .. '" after '
              .. tostring(MAX_WRITE_ATTEMPTS)
              .. ' attempts')
    end
    local ts = os.time(os.date('*t'))
    for key, value in pairs(metrics) do
        file:write(ts .. ':' .. key .. ':' .. value .. '\n')
    end
    file:flush()
    io.close(file)
end

function main()
    local counter = 0
    -- we don't catch http://luaq.ru/OnStop.html to survive QUIK restarts
    while true do
        counter = counter + 1
        write_metrics({
            is_connected = isConnected(),
            avg_ping_duration = getInfoParam('AVGPINGDURATION'),
            avg_sent = getInfoParam('AVGSENT'),
            avg_rect = getInfoParam('AVGRECV'),
            max_ping_duration = getInfoParam('MAXPINGDURATION'),
            orders = getInfoParam('orders'),
            futures_client_holding = getNumberOf('futures_client_holding'),
            trades = getNumberOf('trades'),
            orders = getNumberOf('orders'),
            stop_orders = getNumberOf('stop_orders'),
            account_balance = getNumberOf('account_balance')
        }, counter)
        sleep(SLEEP_PERIOD_MSEC)
    end
end
