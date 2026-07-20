// The public surface of the engine. A UI or a console harness imports this one
// file and gets the whole game, without reaching into the internals.

export 'models/enums.dart';
export 'models/crew.dart';
export 'models/world.dart';
export 'models/run.dart';
export 'models/profile.dart';

export 'config/game_config.dart';
export 'config/difficulty.dart';

export 'content/roster.dart';
export 'content/sites.dart';
export 'content/buildings.dart';
export 'content/research.dart';
export 'content/events.dart';
export 'content/text.dart';

export 'engine/rng.dart';
export 'engine/result.dart';
export 'engine/action_economy.dart';
export 'engine/day_resolver.dart';
export 'engine/game_engine.dart';

export 'systems/ending_system.dart';
export 'systems/unlock_system.dart';
export 'systems/building_system.dart';

export 'serialization/json_codec.dart';
