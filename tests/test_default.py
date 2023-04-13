from woke.testing import *
from woke.testing.fuzzing import *

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
    pass

chain1 = Chain()
chain2 = Chain()

@chain1.connect(chain_id=1)
@chain2.connect(chain_id=2)
def test_default():
    global AxelarGatewayChain1, AxelarGatewayChain2, xAppChain1, xAppChain2
    deployer1 = chain1.accounts[0]
    deployer2 = chain2.accounts[0]
    alice1 = chain1.accounts[1]
    alice2 = chain2.accounts[1]