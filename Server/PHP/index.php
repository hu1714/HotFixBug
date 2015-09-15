<?php
function response($res){
	echo '{';
	$count = 0;
	foreach ( $res as $key => $value){
		if ($count != 0){
			echo ',';
		}
		echo '"'.$key.'"'.':'.'"'.$value.'"';
		$count = $count + 1;
	}
	echo '}';
}

function buildNum($value){
	$sp = explode("_",$value);
	$end = explode(".",$sp[1]);
	$build = (int)$end[0];
	return $build;
}
function targetPatch($fs){
	$target = null;
	$max = 0;
	foreach ($fs as $value){
		if ( strstr($value,".js") != false){
			$build = buildNum($value);
			if($build >= $max){
				$max = $build;
				$target = $value;
			}
		}
	}
	return $target;
}

	$HOST = 'http://127.0.0.1';

	$appVersion = $_POST['appversion'];
	$curPatch = $_POST['cur_patch'];
	if (is_dir($appVersion)){
		$fs=scandir($appVersion);
		$target = targetPatch($fs);
		if ( $target == null){
			response(['errno' => '1']);
		}else{
			if ($target == $curPatch){
				response(['errno' => '2']);
			}else{
				$res = ['errno' => '0'];
				$res['patch_name'] = $target;
				$res['patch_url'] = $HOST.'/'.$appVersion.'/'.$target;
				response($res);
			}
		}
	}else{
		response(['errno' => '3','appversion' => $appVersion]);
	}
?>
