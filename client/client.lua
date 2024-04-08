-- CLIENT

CORE.ISReady()

while not CORE.ISReady() do
    Citizen.Wait(400)
    print("WAIT FOR CORE")
end

CORE.Player()
CORE.Police()
CORE.Stash()
