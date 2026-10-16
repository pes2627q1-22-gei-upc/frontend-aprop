#!/usr/bin/env python3
"""Proves dels hooks d'IA. Executa: python3 -m unittest discover -s scripts/ai/tests"""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

AI = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(AI))
from commit_msg import validate  # noqa: E402


def run_guard(payload: dict) -> dict:
    result = subprocess.run(
        [sys.executable, str(AI / "hooks/guard.py")], input=json.dumps(payload), capture_output=True, text=True, timeout=30
    )
    return json.loads(result.stdout)


def cursor(command: str, cwd: str = ".") -> str:
    return run_guard({"command": command, "cwd": cwd})["permission"]


def antigravity(command: str, cwd: str = ".") -> str:
    return run_guard({"toolCall": {"name": "run_command", "args": {"CommandLine": command, "Cwd": cwd}}})["decision"]


class CommitMessageTest(unittest.TestCase):
    def test_accepts_team_format(self):
        self.assertIsNone(validate("Tasca #42 Autenticació Google: Implementació de la validació de tokens JWT en el backend"))

    def test_rejects_missing_task(self):
        self.assertIsNotNone(validate("Add reusable event details screen"))

    def test_rejects_vague_description(self):
        self.assertIsNotNone(validate("Tasca #7 Login: fix"))

    def test_allows_merge_commits(self):
        self.assertIsNone(validate("Merge pull request #3 from pes2627q1-22-gei-upc/feature/event-details"))


class GuardTest(unittest.TestCase):
    def setUp(self):
        self.repo = tempfile.mkdtemp()
        subprocess.run(["git", "init", "-q", "-b", "develop", self.repo], check=True)
        subprocess.run(["git", "-C", self.repo, "commit", "-q", "--allow-empty", "-m", "init"], check=True,
                       env={"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
                            "GIT_COMMITTER_EMAIL": "t@t", "PATH": "/usr/bin:/bin"})

    def test_blocks_rm_rf(self):
        self.assertEqual(cursor("rm -rf build"), "deny")
        self.assertEqual(antigravity("rm -fr lib"), "deny")

    def test_blocks_force_push(self):
        self.assertEqual(cursor("git push --force origin feature/x"), "deny")
        self.assertEqual(antigravity("git push -f"), "deny")

    def test_blocks_push_to_protected_branch(self):
        self.assertEqual(cursor("git push origin develop"), "deny")

    def test_asks_before_normal_push(self):
        self.assertEqual(cursor("git push -u origin feature/ai-setup", self.repo), "ask")
        self.assertEqual(antigravity("git push -u origin feature/ai-setup", self.repo), "force_ask")

    def test_blocks_commit_on_protected_branch(self):
        self.assertEqual(cursor('git commit -m "Tasca #1 Títol: Descripció prou llarga"', self.repo), "deny")

    def test_blocks_bad_commit_message_on_feature_branch(self):
        subprocess.run(["git", "-C", self.repo, "switch", "-q", "-c", "feature/x"], check=True)
        self.assertEqual(cursor('git commit -m "wip"', self.repo), "deny")
        self.assertEqual(cursor('git commit -m "Tasca #1 Títol: Descripció prou llarga"', self.repo), "ask")

    def test_blocks_staged_env_file(self):
        subprocess.run(["git", "-C", self.repo, "switch", "-q", "-c", "feature/x"], check=True)
        Path(self.repo, ".env").write_text("APP_TOKEN=abc\n")
        subprocess.run(["git", "-C", self.repo, "add", "-f", ".env"], check=True)
        self.assertEqual(cursor('git commit -m "Tasca #1 Títol: Descripció prou llarga"', self.repo), "deny")

    def test_blocks_reading_env_but_not_example(self):
        self.assertEqual(cursor("cat .env"), "deny")
        self.assertEqual(cursor("cat .env.example"), "allow")
        view = run_guard({"toolCall": {"name": "view_file", "args": {"AbsolutePath": "/repo/.env"}}})
        self.assertEqual(view["decision"], "deny")

    def test_allows_regular_commands(self):
        self.assertEqual(cursor("git status --short"), "allow")
        self.assertEqual(antigravity("flutter test"), "allow")

    def test_asks_for_risky_git(self):
        self.assertEqual(cursor("git reset --hard HEAD~1"), "ask")
        self.assertEqual(cursor("git add -A"), "ask")


class PendingDecisionsTest(unittest.TestCase):
    def setUp(self):
        sys.path.insert(0, str(AI / "hooks"))
        from pending_decisions import unregistered
        self.unregistered = unregistered
        self.repo = Path(tempfile.mkdtemp())
        env = {"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
               "GIT_COMMITTER_EMAIL": "t@t", "PATH": "/usr/bin:/bin"}
        (self.repo / "docs").mkdir()
        (self.repo / "docs/decisions-pendents.md").write_text("### DP-001 · Prova\n", encoding="utf-8")
        (self.repo / "lib").mkdir()
        (self.repo / "pubspec.yaml").write_text("dependencies:\n  flutter:\n    sdk: flutter\n", encoding="utf-8")
        subprocess.run(["git", "init", "-q", str(self.repo)], check=True)
        subprocess.run(["git", "-C", str(self.repo), "add", "."], check=True)
        subprocess.run(["git", "-C", str(self.repo), "commit", "-q", "-m", "init"], check=True, env=env)

    def test_flags_unregistered_todo_in_code(self):
        (self.repo / "lib/a.dart").write_text("// TODO(confirmar): format de la data\n", encoding="utf-8")
        self.assertEqual(len(self.unregistered(self.repo)), 1)

    def test_accepts_registered_dp_marker(self):
        (self.repo / "lib/a.dart").write_text("// TODO(DP-001): format de la data\n", encoding="utf-8")
        self.assertEqual(self.unregistered(self.repo), [])

    def test_flags_unknown_dp_marker(self):
        (self.repo / "lib/a.dart").write_text("// TODO(DP-042)\n", encoding="utf-8")
        self.assertIn("DP-042", self.unregistered(self.repo)[0])

    def test_flags_new_dependency(self):
        (self.repo / "pubspec.yaml").write_text(
            "dependencies:\n  flutter:\n    sdk: flutter\n  provider: ^6.0.0\n", encoding="utf-8")
        self.assertIn("provider", self.unregistered(self.repo)[0])

    def test_ignores_documentation(self):
        (self.repo / "docs/notes.md").write_text("TODO(confirmar) a la doc\n", encoding="utf-8")
        self.assertEqual(self.unregistered(self.repo), [])


if __name__ == "__main__":
    unittest.main()
