"""Host-side log acceptance tests; no RTL simulation or TD execution."""
import unittest
from pathlib import Path
import subprocess
import sys
import tempfile

from tools.build_five_bank import td_error_lines


class TdLogValidationTests(unittest.TestCase):
    def test_routing_error_before_completion_is_rejected(self):
        error = 'PHY-8023 ERROR: Location: (x28y7_local5), nets: u_alarm_wave/mux92_syn_2[240] u_alarm_wave/mux92_syn_2[0]'
        log = error + '\nBIT-1004 : Generate bits file case_a_5bank.bit.\nFIVE_BANK_TD_BUILD_COMPLETE\n'
        self.assertEqual(td_error_lines(log), [error])

    def test_plain_and_critical_errors_are_rejected(self):
        lines = ['ERROR: routing failed', ' HDL-1000 CRITICAL-ERROR: invalid net']
        self.assertEqual(td_error_lines('\n'.join(lines)), lines)

    def test_warnings_and_error_named_signals_are_not_failures(self):
        log = ('HDL-7225 CRITICAL-WARNING: already implicitly declared\n'
               'SYN-5000 WARNING: error_code is unused\n'
               'RUN-1001 : error_code[0] connected\nFIVE_BANK_TD_BUILD_COMPLETE\n')
        self.assertEqual(td_error_lines(log), [])

    def test_packager_rejects_error_before_creating_release(self):
        script = Path(__file__).resolve().parents[1] / 'tools/package_five_bank.py'
        with tempfile.TemporaryDirectory() as temporary:
            build = Path(temporary) / 'build'
            project = build / 'src/td_project'
            project.mkdir(parents=True)
            (build / 'source_sha256.json').write_text('{}', encoding='utf-8')
            (project / 'build_five_bank.log').write_text(
                'PHY-8023 ERROR: Location: (x28y7_local5), nets: a b\n'
                'FIVE_BANK_TD_BUILD_COMPLETE\n', encoding='utf-8')
            release = Path(temporary) / 'release'
            result = subprocess.run([sys.executable, str(script), str(build),
                                     '--release', str(release)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('TD errors prohibit packaging', result.stderr)
            self.assertFalse(release.exists())


if __name__ == '__main__':
    unittest.main()
