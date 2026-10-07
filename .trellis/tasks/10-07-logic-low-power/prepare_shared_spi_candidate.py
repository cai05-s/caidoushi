"""Prepare shared SPI candidate with unchanged standalone module interfaces."""
from pathlib import Path
import difflib
import hashlib
import json
import re
from check_first_candidates import BASELINE, TASK
from prepare_first_candidates import preserve_newlines

FOLDER = TASK / 'candidates/e_shared_flash_spi'
HDL = 'src/user_source/hdl_source/'


def split_controller(source, name, clock_parameter, physical, signals, instance_name):
    header_end = source.index('\n);') + len('\n);')
    header, body = source[:header_end], source[header_end:]
    parameter_names = re.findall(r'parameter\s+(?:integer\s+|\[[^\]]+\]\s+)(\w+)\s*=', header)
    ports = re.findall(r'^\s*(?:input|output)\s+(?:wire|reg)\s+(?:\[[^\]]+\]\s*)?(\w+)\s*,?\s*$', header, re.M)
    assert ports and parameter_names
    sclk, mosi, miso = physical
    start, tx, busy, done, rx = signals
    engine_pattern = r'    spi_byte_engine #\(\.CLK_DIV\(' + clock_parameter + r'\)\) ' + instance_name + r' \(.*?    \);'
    engine = re.search(engine_pattern, body, re.S).group(0)
    core_header = header.replace('module ' + name + ' #(', 'module ' + name + '_control #(')
    for port in physical:
        core_header, count = re.subn(r'^\s*(?:input|output)\s+wire\s+' + port + r',\n', '', core_header, count=1, flags=re.M)
        assert count == 1
    core_header = core_header[:-len('\n);')] + ''',
    output wire        engine_start,
    output wire [7:0]  engine_tx,
    input wire         engine_busy,
    input wire         engine_done,
    input wire [7:0]   engine_rx
);'''
    core_body = body.replace(engine, f'''    assign engine_start = {start};
    assign engine_tx = {tx};
    assign {busy} = engine_busy;
    assign {done} = engine_done;
    assign {rx} = engine_rx;''')
    wrapper_header = re.sub(r'\boutput\s+reg\b', 'output wire', header)
    params = ',\n        '.join(f'.{p}({p})' for p in parameter_names)
    links = [f'.{p}({p})' for p in ports if p not in physical]
    links += ['.engine_start(engine_start)', '.engine_tx(engine_tx)', '.engine_busy(engine_busy)', '.engine_done(engine_done)', '.engine_rx(engine_rx)']
    link_text = ',\n        '.join(links)
    wrapper = wrapper_header + f'''
    // Standalone wrapper retains the original ports, parameters and SPI engine.
    wire engine_start, engine_busy, engine_done;
    wire [7:0] engine_tx, engine_rx;
    {name}_control #(
        {params}
    ) u_control (
        {link_text}
    );
    spi_byte_engine #(.CLK_DIV({clock_parameter})) {instance_name} (
        .clk(clk), .rst_n(rst_n), .start(engine_start), .tx_byte(engine_tx),
        .miso({miso}), .busy(engine_busy), .done(engine_done),
        .rx_byte(engine_rx), .sclk({sclk}), .mosi({mosi})
    );
endmodule

'''
    # The second module reuses every original controller state/task/function.
    return wrapper + core_header.replace('`timescale 1ns/1ps\n\n', '', 1) + core_body


def main():
    FOLDER.mkdir(parents=True, exist_ok=True)
    records = {}
    configurations = [
        ('w25q64_record_store', 'CLK_DIV', ('spi_sclk','spi_mosi','spi_miso'),
         ('byte_start','byte_tx','byte_busy','byte_done','byte_rx'), 'u_byte_engine'),
        ('w25q64_preflight_reader', 'SPI_CLK_DIV', ('flash_sclk','flash_mosi','flash_miso'),
         ('spi_start','spi_tx_byte','spi_busy','spi_done','spi_rx_byte'), 'u_spi_byte_engine')]
    for name, divider, physical, signals, instance_name in configurations:
        relative = HDL + name + '.v'
        original = (BASELINE / relative).read_bytes()
        text = original.decode('utf-8').replace('\r\n', '\n')
        modified = split_controller(text, name, divider, physical, signals, instance_name)
        records[relative] = (original, preserve_newlines(original, modified))

    relative = HDL + 'player_settings_flash.v'
    original = (BASELINE / relative).read_bytes()
    source = original.decode('utf-8').replace('\r\n', '\n')
    addition = '''    // The identity/read-only phase and journal phase own one byte engine.
    // Both existing owners use CLK_DIV=5; standalone wrappers keep their own.
    wire pf_byte_start, st_byte_start, shared_byte_busy, shared_byte_done;
    wire [7:0] pf_byte_tx, st_byte_tx, shared_byte_rx;
    wire shared_sclk, shared_mosi;
    assign pf_clk=shared_sclk;
    assign st_clk=shared_sclk;
    assign pf_mosi=shared_mosi;
    assign st_mosi=shared_mosi;
'''
    marker = '    // 记录在整个CRC计算期间保持不变'
    assert marker in source
    changed = source.replace(marker, addition + marker, 1)
    changed = changed.replace('    w25q64_preflight_reader #(', '    w25q64_preflight_reader_control #(')
    changed = changed.replace('.start(pf_start),.flash_miso(flash_miso),', '.start(pf_start),')
    changed = changed.replace('.flash_sclk(pf_clk),.flash_mosi(pf_mosi),', '')
    changed = changed.replace('.jedec_id(jedec_id),.status1(),.status2(),.status3());', '''.jedec_id(jedec_id),.status1(),.status2(),.status3(),
        .engine_start(pf_byte_start),.engine_tx(pf_byte_tx),
        .engine_busy(shared_byte_busy),.engine_done(shared_byte_done),.engine_rx(shared_byte_rx));''')
    changed = changed.replace('    w25q64_record_store #(', '    w25q64_record_store_control #(')
    changed = changed.replace('.spi_sclk(st_clk),.spi_mosi(st_mosi),.spi_miso(flash_miso),', '')
    changed = changed.replace('.spi_wp_n(st_wp),.spi_hold_n(st_hold));', '''.spi_wp_n(st_wp),.spi_hold_n(st_hold),
        .engine_start(st_byte_start),.engine_tx(st_byte_tx),
        .engine_busy(shared_byte_busy),.engine_done(shared_byte_done),.engine_rx(shared_byte_rx));''')
    engine = '''    spi_byte_engine #(.CLK_DIV(5)) u_shared_byte_engine (
        .clk(clk),.rst_n(rst_n && !boot_abort),
        .start(pf_owner ? pf_byte_start : st_byte_start),
        .tx_byte(pf_owner ? pf_byte_tx : st_byte_tx),.miso(flash_miso),
        .busy(shared_byte_busy),.done(shared_byte_done),.rx_byte(shared_byte_rx),
        .sclk(shared_sclk),.mosi(shared_mosi)
    );

'''
    marker = '    always @(posedge clk or negedge rst_n) begin'
    assert changed.count(marker) == 1
    changed = changed.replace(marker, engine + marker)
    records[relative] = (original, preserve_newlines(original, changed))
    manifest = {'candidate':'e_shared_flash_spi','parent':'V1.0','files':{},
                'public_module_ports_parameters_preserved':True,
                'live_source_edited':False,'td_run':False,'rtl_simulation_run':False}
    for relative, (before, after) in records.items():
        name = Path(relative).name
        (FOLDER / name).write_bytes(after)
        (FOLDER / (name + '.diff')).write_text(''.join(difflib.unified_diff(before.decode('utf-8').splitlines(True), after.decode('utf-8').splitlines(True), fromfile='V1.0/'+relative, tofile='e_shared_flash_spi/'+relative)), encoding='utf-8', newline='')
        manifest['files'][relative] = {'parent_sha256':hashlib.sha256(before).hexdigest(),
                                     'candidate_sha256':hashlib.sha256(after).hexdigest(),
                                     'line_ending':'CRLF' if b'\r\n' in before else 'LF'}
    (FOLDER / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n',encoding='utf-8')
    print(json.dumps(manifest, indent=2))


if __name__ == '__main__':
    main()
