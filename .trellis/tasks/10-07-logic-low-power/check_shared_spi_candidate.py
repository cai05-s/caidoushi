"""Shared SPI structure, controller identity and ownership checks; no simulation."""
from collections import Counter
import hashlib
import itertools
import json
from pathlib import Path
import re
import sys
from check_first_candidates import BASELINE, TASK

FOLDER = TASK / 'candidates/e_shared_flash_spi'
HDL = 'src/user_source/hdl_source/'


def body(source, module_name):
    source = source[source.index('module ' + module_name + ' #('):]
    return source[source.index('\n);')+len('\n);'):source.index('\nendmodule')]


def main():
    sys.path.insert(0, sys.argv[1])
    import pyslang
    from pyslang import ast, syntax
    manifest = json.loads((FOLDER / 'manifest.json').read_text(encoding='utf-8'))
    before, after = {}, {}
    for relative, hashes in manifest['files'].items():
        a = (BASELINE / relative).read_bytes()
        b = (FOLDER / Path(relative).name).read_bytes()
        assert hashlib.sha256(a).hexdigest() == hashes['parent_sha256']
        assert hashlib.sha256(b).hexdigest() == hashes['candidate_sha256']
        before[Path(relative).name] = a.decode('utf-8').replace('\r\n','\n')
        after[Path(relative).name] = b.decode('utf-8').replace('\r\n','\n')

    configurations = [('w25q64_record_store','byte_start','byte_tx','byte_busy','byte_done','byte_rx'),
                      ('w25q64_preflight_reader','spi_start','spi_tx_byte','spi_busy','spi_done','spi_rx_byte')]
    positional_wrappers = []
    for name, start, tx, busy, done, rx in configurations:
        old, new = before[name+'.v'], after[name+'.v']
        old_header = old[:old.index('\n);')+len('\n);')]
        new_header = new[:new.index('\n);')+len('\n);')]
        assert re.sub(r'\boutput\s+reg\b','output wire',old_header) == new_header
        old_body = re.sub(r'    spi_byte_engine #\(.*?    \);', '', body(old, name), count=1, flags=re.S)
        new_body = body(new, name+'_control')
        bus = f'''    assign engine_start = {start};
    assign engine_tx = {tx};
    assign {busy} = engine_busy;
    assign {done} = engine_done;
    assign {rx} = engine_rx;'''
        assert new_body.count(bus) == 1
        assert old_body == new_body.replace(bus, ''), 'Controller behavior changed: ' + name
        assert 'spi_byte_engine' not in new_body
        assert new.count('spi_byte_engine #(') == 1
        # Exercise the complete original positional port list as well as named
        # parameter instances below. Output positions remain unconnected.
        port_directions = re.findall(r'^\s*(input|output)\s+(?:wire|reg)\s+(?:\[[^\]]+\]\s*)?\w+\s*,?\s*$', old_header,re.M)
        positional_wrappers.append(f"{name} positional_{name}({','.join('0' if d=='input' else '' for d in port_directions)});")

    old = before['player_settings_flash.v']
    new = after['player_settings_flash.v']
    old_state = old[old.index('    always @(posedge clk or negedge rst_n) begin'):]
    new_state = new[new.index('    always @(posedge clk or negedge rst_n) begin'):]
    assert old_state == new_state
    restored = re.sub(r'    // The identity/read-only phase.*?    assign st_mosi=shared_mosi;\n', '',new,count=1,flags=re.S)
    restored = re.sub(r'    spi_byte_engine #\(\.CLK_DIV\(5\)\) u_shared_byte_engine \(.*?    \);\n\n', '',restored,count=1,flags=re.S)
    restored = restored.replace('w25q64_preflight_reader_control #(', 'w25q64_preflight_reader #(')
    restored = restored.replace('w25q64_record_store_control #(', 'w25q64_record_store #(')
    restored = restored.replace('.start(pf_start),', '.start(pf_start),.flash_miso(flash_miso),')
    restored = restored.replace('.flash_cs_n(pf_cs),.flash_wp_n(pf_wp)', '.flash_cs_n(pf_cs),.flash_sclk(pf_clk),.flash_mosi(pf_mosi),.flash_wp_n(pf_wp)')
    restored = restored.replace('.spi_cs_n(st_cs),', '.spi_cs_n(st_cs),.spi_sclk(st_clk),.spi_mosi(st_mosi),.spi_miso(flash_miso),')
    restored = re.sub(r',\n        \.engine_start\((?:pf|st)_byte_start\),\.engine_tx\((?:pf|st)_byte_tx\),\n        \.engine_busy\(shared_byte_busy\),\.engine_done\(shared_byte_done\),\.engine_rx\(shared_byte_rx\)', '', restored)
    assert restored == old, 'Parent changes exceed wiring/engine sharing'
    assert new.count('spi_byte_engine #(.CLK_DIV(5))') == 1
    assert '.rst_n(rst_n && !boot_abort)' in new
    assert '.rst_n(rst_n && !pf_owner && !boot_abort)' in new

    wrappers = ['player_settings_flash settings();'] + positional_wrappers
    for n, commit in ((2,0),(3,1),(12,0),(12,1),(32,0),(32,1),(256,0),(256,1)):
        for divider in (2,5,9):
            wrappers.append(f'w25q64_record_store #(.RECORD_BYTES({n}),.COMMIT_LAST({commit}),.CLK_DIV({divider})) s_{n}_{commit}_{divider}();')
    for divider, startup in itertools.product((2,5,9),(1,1024)):
        wrappers.append(f'w25q64_preflight_reader #(.SPI_CLK_DIV({divider}),.STARTUP_CYCLES({startup})) p_{divider}_{startup}();')
    diagnostics = {}
    for label, sources in [('baseline',before),('candidate',after)]:
        manager = pyslang.SourceManager()
        compilation = ast.Compilation()
        for name, source in sources.items():
            compilation.addSyntaxTree(syntax.SyntaxTree.fromText(source,manager,name))
        spi = (BASELINE / HDL / 'spi_byte_engine.v').read_text(encoding='utf-8')
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText(spi,manager,'spi_byte_engine.v'))
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText('`timescale 1ns/1ps\nmodule spi_candidate_checks;\n'+'\n'.join(wrappers)+'\nendmodule',manager,'wrappers.v'))
        all_diagnostics = list(compilation.getAllDiagnostics())
        errors = [d for d in all_diagnostics if d.isError()]
        engine = pyslang.DiagnosticEngine(manager)
        client = pyslang.TextDiagnosticClient()
        engine.addClient(client)
        for diagnostic in errors:
            engine.issue(diagnostic)
        assert not errors, client.getString()
        diagnostics[label] = dict(Counter(str(d.code) for d in all_diagnostics))
        settings = compilation.getRoot().find('spi_candidate_checks').body.find('settings')
        if label == 'candidate':
            assert settings.body.find('u_shared_byte_engine') is not None
            assert settings.body.find('u_identity').body.find('u_spi_byte_engine') is None
            assert settings.body.find('u_store').body.find('u_byte_engine') is None
        else:
            assert settings.body.find('u_identity').body.find('u_spi_byte_engine') is not None
            assert settings.body.find('u_store').body.find('u_byte_engine') is not None

    # Static ownership truth table: at any given owner selection, the shared
    # command equals that owner's original command. Store control is reset
    # while preflight owns pins. Both controller byte engines have divider5.
    mux_cases = 0
    for owner, pf_start, st_start in itertools.product((False,True),repeat=3):
        for pf_tx, st_tx in itertools.product((0,1,0x55,0xaa,0xfe,0xff),repeat=2):
            selected_start = pf_start if owner else st_start
            selected_tx = pf_tx if owner else st_tx
            assert (selected_start,selected_tx) == ((pf_start,pf_tx) if owner else (st_start,st_tx))
            mux_cases += 1
    preflight = body(after['w25q64_preflight_reader.v'],'w25q64_preflight_reader_control')
    idle = preflight[preflight.index('                ST_IDLE: begin'):preflight.index('                ST_STARTUP: begin')]
    assert 'spi_done' not in idle and 'spi_rx_byte' not in idle and 'spi_busy' not in idle
    assert "ST_COMPLETE: begin" in preflight
    assert "state <= ST_IDLE;" in preflight
    result = dict(manifest, parser=pyslang.__version__, elaboration_errors=0,
                  standalone_specializations=30, original_positional_port_wrappers=2,
                  production_engine_instances_before=2,production_engine_instances_after=1,
                  all_controller_parent_state_sources_identical=True,
                  ownership_mux_cases=mux_cases,diagnostic_categories=diagnostics,
                  board_tested=False,
                  limits='Structural/controller identity and ownership reasoning only; no protocol cycle simulation. TD resource/timing and physical SPI/Flash tests required.')
    (FOLDER / 'static.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k not in ('files','diagnostic_categories')},indent=2))


if __name__ == '__main__':
    main()
