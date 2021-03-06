require './lib/transfer'
require 'digest'
require './lib/peer'

class Block < ActiveRecord::Base
  has_one :transfer

  validates_associated :transfer, {:is_valid => true}
  before_create(:valid_transaction)

  def valid_transaction
    transfer = Transfer.where({:block_id => nil}).first
    self.transfer = transfer
    if !transfer.is_valid?
      throw :abort
    else
      transfer.update_peers
      mine
    end
  end

  def mine
    if Block.all.empty?
      self.prev_hash = nil
    else
      self.prev_hash = Block.all.last.own_hash
    end
    self.message = transfer.message
    self.nonce = calc_nonce(prev_hash)
    self.own_hash = calc_hash(message, prev_hash, nonce)
    miner = Peer.find(miner_id.to_i)
    new_balance = miner.balance + 13
    miner.update({:balance => new_balance})
  end

  def calc_hash(message, prev_hash, nonce)
    Digest::SHA256.hexdigest([message, prev_hash, nonce].compact.join)
  end

  def calc_nonce(prev_hash)
    num_zeroes = 4
    nonce = "MISHA ANDREW JOHN JARED AND DAVID ARE THE BEST"
    count = 0
    until calc_hash(message, prev_hash, nonce).start_with?("0" * num_zeroes)
      nonce = nonce.next
      count += 1
    end
    nonce
  end

end
