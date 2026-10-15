import random
import time
from enum import Enum
from typing import List, Dict, Optional

class State(Enum):
    FOLLOWER = 1
    CANDIDATE = 2
    LEADER = 3

class RaftNode:
    def __init__(self, node_id: int, all_nodes: List[int]):
        self.id = node_id
        self.nodes = all_nodes
        self.state = State.FOLLOWER
        self.current_term = 0
        self.voted_for: Optional[int] = None
        self.log: List[str] = []
        self.commit_index = 0
        self.last_heartbeat = time.time()
        self.election_timeout = self._random_timeout()

    def _random_timeout(self) -> float:
        return time.time() + random.uniform(1.0, 2.0)

    def on_heartbeat(self, term: int):
        if term >= self.current_term:
            self.current_term = term
            self.state = State.FOLLOWER
            self.voted_for = None
            self.last_heartbeat = time.time()
            self.election_timeout = self._random_timeout()

    def start_election(self):
        self.current_term += 1
        self.state = State.CANDIDATE
        self.voted_for = self.id
        votes = 1  # vote for self

        # Simulate requesting votes from others
        for node_id in self.nodes:
            if node_id == self.id:
                continue
            # In real Raft, we'd send RequestVote RPC
            # Here, we simulate: grant vote if term is higher and log is not behind
            votes += 1  # Simplified: assume all grant vote

        if votes > len(self.nodes) // 2:
            self.state = State.LEADER
            print(f"Node {self.id} elected leader in term {self.current_term}")

    def append_entry(self, entry: str):
        if self.state == State.LEADER:
            self.log.append(entry)
            print(f"Leader {self.id} appended: {entry}")
            # In real system, replicate to followers
            self.commit_index = len(self.log) - 1

    def tick(self):
        now = time.time()
        if self.state == State.LEADER:
            # Send heartbeat (simplified)
            pass
        elif now > self.election_timeout:
            self.start_election()
        elif self.state == State.FOLLOWER and now - self.last_heartbeat > 2.0:
            # Missed heartbeats → start election
            self.election_timeout = self._random_timeout()
            self.start_election()


def simulate_raft():
    node_ids = [1, 2, 3]
    nodes = [RaftNode(i, node_ids) for i in node_ids]

    # Simulate time steps
    for step in range(20):
        time.sleep(0.5)
        print(f"\n--- Step {step + 1} ---")

        # Randomly trigger heartbeat from current leader (if any)
        leaders = [n for n in nodes if n.state == State.LEADER]
        if leaders:
            leader = random.choice(leaders)
            for node in nodes:
                if node.id != leader.id:
                    node.on_heartbeat(leader.current_term)
            # Leader appends a command every few steps
            if step % 5 == 0:
                leader.append_entry(f"command-{step}")

        # Each node processes its state
        for node in nodes:
            node.tick()

        # Print status
        for node in nodes:
            print(f"Node {node.id}: {node.state.name} | Term {node.current_term} | Log len {len(node.log)}")


if __name__ == "__main__":
    print(" Simulating Raft Consensus for Drone Swarm Coordination\n")
    simulate_raft()
