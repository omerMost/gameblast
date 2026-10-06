extends ContentSearch
## Original-level real launcher inputs, keyed by prototype level number.
const SHOTS := {
	6: [[45.0,0.6,"grenade"]],
	7: [[5,0.8,"grenade"]],
	8: [[5.0,0.7,"grenade"]],
	9: [[15.0,0.6,"grenade"]],
	10: [[65.0,0.7,"grenade"],[5.0,0.5,"grenade"]],
	11: [[5.0,0.8,"grenade"]],
	12: [[5,0.7,"grenade"],[25,0.9,"grenade"],[25,0.8,"grenade"]],
	13: [[15,0.7,"grenade"],[25,0.9,"grenade"]],
	14: [[35,0.7,"grenade"],[5,0.5,"grenade"]],
	15: [[5,0.7,"grenade"]],
	16: [[5,1.0,"grenade"],[25,0.3,"rocket"]],
	17: [[30,0.9,"grenade"],[55,0.5,"grenade"]],
	18: [[20,1.0,"grenade"],[5,0.4,"grenade"]],
}
func _ready() -> void:
 await TestUtil.boot(self)
 g=Debug.game
 var only := -1
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--level="): only=int(arg.split("=")[1])
 for number in SHOTS:
  if only>0 and only!=number: continue
  tried=0
  var result: Dictionary=await run_shots(number-1,SHOTS[number])
  if not result.win:
   # ADR0006: retry identical controls against chaotic simulation history,
   # then bound search using the unchanged original level and ammo.
   result=await run_shots(number-1,SHOTS[number])
  if not result.win: result=await solve(number-1)
  print("EARLY L",number," ",JSON.stringify(result)," tried=",tried)
  if result.win: solutions[str(number)]=result.seq
  else: failures.append(number)
 print("EARLY cleared=",solutions.size()," failures=",failures)
 print("EARLY RESULT: ","PASS" if failures.is_empty() else "FAIL")
 await TestUtil.finish(self,0 if failures.is_empty() else 1)
