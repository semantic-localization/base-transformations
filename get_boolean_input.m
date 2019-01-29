function flag = get_boolean_input(msg)
  msg = sprintf('%s - y/n ', msg);  
  flag = false;
  while true
    s = input(msg, 's');
    if numel(s) > 0
      s = lower(s);
      if s(1) == 'y' || s(1) == 'n'
        if s(1) == 'y'
          flag = true;
        end
        break;
      end
    end
  end
end
