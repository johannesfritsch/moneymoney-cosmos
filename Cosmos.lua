-- Inofficial Cosmos Extension for MoneyMoney
-- Fetches Cosmos quantity for address via Cosmos mainnet API
-- Fetches Cosmos price in EUR via cryptocompare API
-- Returns cryptoassets as securities
--
-- Username: Cosmos Adresses comma seperated
-- Password: Does not matter

-- MIT License

-- Copyright (c) 2022 Johannes Fritsch

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


WebBanking{
  version = 0.1,
  description = "Include your Cosmos as cryptoportfolio in MoneyMoney by providing Cosmos adresses (username, comma seperated)",
  services= { "Cosmos" }
}

local atomAddresses
local coinbaseApiKey
local connection = Connection()
local currency = "EUR" -- fixme: make dynamic if MoneyMoney enables input field

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Cosmos"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  atomAddresses = username:gsub("%s+", "")
  coinbaseApiKey = password
end

function ListAccounts (knownAccounts)
  local account = {
    name = "Cosmos",
    accountNumber = "Crypto Asset Cosmos",
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function RefreshAccount (account, since)
  local s = {}
  prices = requestAtomPrice()

  for address in string.gmatch(atomAddresses, '([^,]+)') do
    microAtomQuantity = requestMicroAtomForAtomAddress(address)
    microAtomQuantityDelegated = requestMicroAtomDelegatedForAtomAddress(address)
    atomQuantity = convertMicroAtomToAtom(microAtomQuantity)
    atomQuantityDelegated = convertMicroAtomToAtom(microAtomQuantityDelegated)

    s[#s+1] = {
      name = address,
      currency = nil,
      market = "cryptocompare",
      quantity = atomQuantity,
      price = prices["EUR"],
    }

    s[#s+1] = {
      name = address .. " (Delegated)",
      currency = nil,
      market = "cryptocompare",
      quantity = atomQuantityDelegated,
      price = prices["EUR"],
    }
  end

  return {securities = s}
end

function EndSession ()
end


-- Querry Functions
function requestAtomPrice()
  content = connection:request("GET", cryptocompareRequestUrl(), {})
  json = JSON(content)

  return json:dictionary()
end

function requestMicroAtomForAtomAddress(atomAddress)
  content = connection:get("https://api.cosmos.network/bank/balances/" .. atomAddress)
  json = JSON(content)

  return json:dictionary()["result"][1]["amount"]
end

function requestMicroAtomDelegatedForAtomAddress(atomAddress)
  content = connection:get("https://api.cosmos.network/staking/delegators/" .. atomAddress .. "/delegations")
  json = JSON(content)

  return json:dictionary()["result"][1]["balance"]["amount"]
end


-- Helper Functions
function convertMicroAtomToAtom(lamports)
  return lamports / 1000000
end

function cryptocompareRequestUrl()
  return "https://min-api.cryptocompare.com/data/price?fsym=ATOM&tsyms=EUR,USD"
end
