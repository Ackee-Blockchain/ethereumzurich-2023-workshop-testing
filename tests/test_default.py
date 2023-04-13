from woke.testing import *
from woke.testing.fuzzing import *
from pytypes.axelarnetwork.axelargmpsdksolidity.contracts.interfaces.IAxelarExecutable import IAxelarExecutable

from pytypes.axelarnetwork.axelargmpsdksolidity.contracts.test.ERC20MintableBurnable import ERC20MintableBurnable
from pytypes.contracts.MyContract import MyContract
from pytypes.contracts.mock.AxelarGatewayMock import AxelarGatewayMock

'''
TODO:

- [ ] Deploy tokens on both chains
- [ ] Deploy gateway on both chains
- [ ] Register tokens on gateway
- [ ] Deploy MyContract on both chains
- [ ] Mint some tokens on chain 1
- [ ] Approve them to MyContract on chain 1
- [ ] Send tokens from chain 1 to chain 2
- [ ] Write relayer
- [ ] Relay messages
'''

AxelarGatewayChain1: AxelarGatewayMock
AxelarGatewayChain2: AxelarGatewayMock
xAppChain1: MyContract
xAppChain2: MyContract

def relay(tx: TransactionAbc) -> None:
    for event in tx.events:
        if isinstance(event, AxelarGatewayMock.ContractCallWithToken):
            if event.destinationChain == "chain1":
                dest_chain = chain1
                dest_gw = AxelarGatewayChain1
                src_chain_name = "chain2"
                src_contract = xAppChain2
            elif event.destinationChain == "chain2":
                dest_chain = chain2
                dest_gw = AxelarGatewayChain2
                src_chain_name = "chain1"
                src_contract = xAppChain1
            else:
                raise ValueError(f"Unknown destination chain to relay: {event.destinationChain}")
            
            tx = IAxelarExecutable(event.destinationContractAddress, dest_chain).executeWithToken(
                random_bytes(32),
                src_chain_name,
                str(src_contract.address),
                event.payload,
                event.symbol,
                event.amount,
                from_=dest_gw
            )
            print(tx.call_trace)

chain1 = Chain()
chain2 = Chain()

@chain1.connect(chain_id=1)
@chain2.connect(chain_id=2)
def test_default():
    global AxelarGatewayChain1, AxelarGatewayChain2, xAppChain1, xAppChain2
    deployer1 = chain1.accounts[0]
    deployer2 = chain2.accounts[0]
    alice1 = chain1.accounts[1]
    alice2 = chain2.accounts[2]
    
    usdc1 = ERC20MintableBurnable.deploy("USD Coin", "USDC", 6, from_=deployer1, chain=chain1)
    usdc2 = ERC20MintableBurnable.deploy("USD Coin", "USDC", 6, from_=deployer2, chain=chain2)
    
    gw1 = AxelarGatewayMock.deploy(from_=deployer1, chain=chain1)
    gw2 = AxelarGatewayMock.deploy(from_=deployer2, chain=chain2)
    AxelarGatewayChain1 = gw1
    AxelarGatewayChain2 = gw2
    
    gw1.registerToken(usdc1, from_=deployer1)
    gw2.registerToken(usdc2, from_=deployer2)
    
    mc1 = MyContract.deploy(gw1, from_=deployer1, chain=chain1)
    mc2 = MyContract.deploy(gw2, from_=deployer2, chain=chain2)
    xAppChain1 = mc1
    xAppChain2 = mc2
    
    usdc1.mint(alice1, 10**12, from_=deployer1)
    
    # send tokens from chain 1 to chain 2
    usdc1.approve(mc1, 10**11, from_=alice1)
    
    tx = mc1.bridge("chain2", usdc1.symbol(), [MyContract.TransferData(10**11, alice2.address, bytes())], from_=alice1)
    print(tx.call_trace)
    
    assert(usdc1.balanceOf(alice1) == 9 * 10**11)
    assert(usdc2.balanceOf(alice2) == 0)
    relay(tx)
    assert(usdc1.balanceOf(alice1) == 9 * 10**11)
    assert(usdc2.balanceOf(alice2) == 10**11)

    # send tokens from chain 2 to chain 1
    usdc2.approve(mc2, 10**11, from_=alice2)

    tx = mc2.bridge("chain1", usdc2.symbol(), [MyContract.TransferData(10**11, alice1.address, bytes())], from_=alice2)
    print(tx.call_trace)
    
    assert usdc1.balanceOf(alice1) == 9 * 10**11
    assert usdc2.balanceOf(alice2) == 0
    relay(tx)
    assert usdc1.balanceOf(alice1) == 10**12
    assert usdc2.balanceOf(alice2) == 0