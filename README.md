# tridecimator

Based on [https://github.com/cnr-isti-vclab/vcglib/tree/main/apps/tridecimator](https://github.com/cnr-isti-vclab/vcglib/tree/main/apps/tridecimator).

### License

GNU General Public License v3.0

### Usage

`./tridecimator fileIn fileOut ratio [opt]`

ratio is between 0.1 and 1.

<table>
	<tr>
		<td>-e#</td>
		<td>QuadricError threshold (range [0,inf) default inf)</td>
	</tr>
	<tr>
		<td>-b#</td>
		<td>Boundary Weight (default .5)</td>
	</tr>
	<tr>
		<td>-p#</td>
		<td>Quality quadric Weight (default .5)</td>
	</tr>
	<tr>
		<td>-q#</td>
		<td>Quality threshold (range [0.0, 0.866], default .3 )</td>
	</tr>
	<tr>
		<td>-n#</td>
		<td>Normal threshold (degree range [0,180] default 90)</td>
	</tr>
	<tr>
		<td>-w#</td>
		<td>Quality weight factor (10)</td>
	</tr>
	<tr>
		<td>-E#</td>
		<td>Minimal admitted quadric value (default 1e-15, must be >0)</td>
	</tr>
	<tr>
		<td>-Q</td>
		<td>Use or not Face Quality Threshold (default yes)</td>
	</tr>
	<tr>
		<td>-H</td>
		<td>Use or not HardQualityCheck (default no)</td>
	</tr>
	<tr>
		<td>-N</td>
		<td>Use or not Face Normal Threshold (default no)</td>
	</tr>
	<tr>
		<td>-P</td>
		<td>Add or not QualityQuadric (default no)</td>
	</tr>
	<tr>
		<td>-A</td>
		<td>Use or not Area Checking (default no)</td>
	</tr>
	<tr>
		<td>-O</td>
		<td>Use or not vertex optimal placement (default yes)</td>
	</tr>
	<tr>
		<td>-S</td>
		<td>Use or not Scale Independent quadric measure (default yes)</td>
	</tr>
	<tr>
		<td>-B</td>
		<td>Preserve or not mesh boundary (default no)</td>
	</tr>
	<tr>
		<td>-T</td>
		<td>Preserve or not Topology (default no)</td>
	</tr>
	<tr>
		<td>-W</td>
		<td>Use or not per vertex Quality to weight the quadric error (default no)</td>
	</tr>
	<tr>
		<td>-C</td>
		<td>Before simplification, remove duplicate & unreferenced vertices</td>
	</tr>
</table>